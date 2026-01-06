import os
import logging
from typing import List, Optional
import boto3
from botocore.exceptions import ClientError
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from langchain.prompts import PromptTemplate

from app.config import settings
from app.models import SourceDocument

logger = logging.getLogger(__name__)


class HealthInsuranceRAG:
    """RAG system for health insurance queries."""
    
    def __init__(self):
        self.vector_store: Optional[FAISS] = None
        self.embeddings = OpenAIEmbeddings(
            model=settings.openai_embedding_model,
            openai_api_key=settings.openai_api_key
        )
        self.llm = ChatOpenAI(
            model=settings.openai_model,
            temperature=settings.temperature,
            max_tokens=settings.max_tokens,
            openai_api_key=settings.openai_api_key
        )
        self.s3_client = boto3.client('s3', region_name=settings.aws_region)
        self.local_index_path = "/tmp/faiss_index"
        
    def load_vector_store(self) -> bool:
        """Load FAISS vector store from local directory or S3."""
        try:
            # Check if running locally (vector_store folder exists)
            local_vector_path = "vector_store"
            if os.path.exists(local_vector_path) and os.path.exists(f"{local_vector_path}/index.faiss"):
                logger.info("Loading vector store from local directory...")
                try:
                    # Try with allow_dangerous_deserialization parameter (newer versions)
                    self.vector_store = FAISS.load_local(
                        local_vector_path,
                        self.embeddings,
                        allow_dangerous_deserialization=True
                    )
                except TypeError:
                    # Fallback for older versions that don't support the parameter
                    self.vector_store = FAISS.load_local(
                        local_vector_path,
                        self.embeddings
                    )
                logger.info("Vector store loaded successfully from local directory")
                return True
            
            # Otherwise, load from S3 (for production/Lambda)
            logger.info("Loading vector store from S3...")
            
            # Create temp directory
            os.makedirs(self.local_index_path, exist_ok=True)
            
            # Download FAISS index files from S3
            index_file = f"{self.local_index_path}/index.faiss"
            pkl_file = f"{self.local_index_path}/index.pkl"
            
            # Download index.faiss
            self.s3_client.download_file(
                settings.s3_bucket_name,
                f"{settings.vector_index_key}/index.faiss",
                index_file
            )
            
            # Download index.pkl
            self.s3_client.download_file(
                settings.s3_bucket_name,
                f"{settings.vector_index_key}/index.pkl",
                pkl_file
            )
            
            # Load the FAISS index
            try:
                # Try with allow_dangerous_deserialization parameter (newer versions)
                self.vector_store = FAISS.load_local(
                    self.local_index_path,
                    self.embeddings,
                    allow_dangerous_deserialization=True
                )
            except TypeError:
                # Fallback for older versions that don't support the parameter
                self.vector_store = FAISS.load_local(
                    self.local_index_path,
                    self.embeddings
                )
            
            logger.info("Vector store loaded successfully from S3")
            return True
            
        except ClientError as e:
            logger.error(f"Failed to load vector store from S3: {e}")
            return False
        except Exception as e:
            logger.error(f"Error loading vector store: {e}")
            return False
    
    def is_loaded(self) -> bool:
        """Check if vector store is loaded."""
        return self.vector_store is not None
    
    def query(self, question: str, conversation_id: Optional[str] = None) -> tuple[str, List[SourceDocument]]:
        """
        Query the RAG system with a health insurance question.
        
        Args:
            question: The user's question
            conversation_id: Optional conversation ID for context
            
        Returns:
            Tuple of (answer, list of source documents)
        """
        if not self.is_loaded():
            raise ValueError("Vector store not loaded. Call load_vector_store() first.")
        
        try:
            # Create a custom prompt for health insurance context
            prompt_template = """You are a helpful health insurance assistant specializing in Medicare and health insurance products. 

IMPORTANT: You should ONLY answer questions related to:
- Medicare (Parts A, B, C, D)
- Health insurance products
- Medicaid
- Health coverage and benefits
- Medical insurance eligibility and enrollment

If the user asks about topics outside of health insurance (like movies, sports, general knowledge, etc.), politely decline and remind them of your specialized purpose.

Use the following context to answer the user's question. If the context doesn't contain relevant information for a health insurance question, say so clearly. Do not make up information.

Context:
{context}

Question: {question}

Provide a clear, accurate, and helpful answer. If the question is not about health insurance, respond with: "I apologize, but I can only assist with health insurance and Medicare-related questions. Please ask me about Medicare coverage, health insurance plans, eligibility, enrollment, or benefits."
"""

            PROMPT = PromptTemplate(
                template=prompt_template,
                input_variables=["context", "question"]
            )
            
            # Create memory for conversation
            memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True,
                output_key="answer"
            )
            
            # Create conversational retrieval chain
            qa_chain = ConversationalRetrievalChain.from_llm(
                llm=self.llm,
                retriever=self.vector_store.as_retriever(
                    search_kwargs={"k": settings.top_k_results}
                ),
                memory=memory,
                return_source_documents=True,
                combine_docs_chain_kwargs={"prompt": PROMPT}
            )
            
            # Run the query
            result = qa_chain({"question": question})
            
            # Extract answer
            answer = result["answer"]
            
            # Process source documents
            sources = []
            
            # Check if the answer indicates an off-topic question
            off_topic_indicators = [
                "only assist with health insurance",
                "not about health insurance",
                "cannot provide",
                "expertise is focused on health insurance"
            ]
            
            is_off_topic = any(indicator.lower() in answer.lower() for indicator in off_topic_indicators)
            
            # Only include sources if the question is on-topic
            if not is_off_topic:
                for doc in result.get("source_documents", []):
                    source_doc = SourceDocument(
                        content=doc.page_content[:300] + "..." if len(doc.page_content) > 300 else doc.page_content,
                        source=doc.metadata.get("source", "Unknown"),
                        page=doc.metadata.get("page", None),
                        score=None  # FAISS doesn't return scores by default
                    )
                    sources.append(source_doc)
            
            logger.info(f"Query processed successfully with {len(sources)} sources")
            return answer, sources
            
        except Exception as e:
            logger.error(f"Error processing query: {e}")
            raise


# Global RAG instance (loaded once on cold start)
rag_system = HealthInsuranceRAG()
