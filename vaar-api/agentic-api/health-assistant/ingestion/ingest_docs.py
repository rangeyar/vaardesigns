#!/usr/bin/env python3
"""
Document Ingestion Script for Health Insurance RAG System

This script processes PDF documents from the health-doc folder, 
creates embeddings, and builds a FAISS vector store that will be 
uploaded to S3 for use by the Lambda function.

Usage:
    python ingest_docs.py
"""

import os
import sys
import logging
from pathlib import Path
from typing import List
import boto3
from dotenv import load_dotenv

from langchain_openai import OpenAIEmbeddings
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DocumentIngestion:
    """Handle document ingestion and vector store creation."""
    
    def __init__(self):
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        self.aws_region = os.getenv("AWS_REGION", "us-east-1")
        self.s3_bucket_name = os.getenv("S3_BUCKET_NAME")
        self.vector_index_key = os.getenv("VECTOR_INDEX_KEY", "faiss_index/health_insurance.index")
        self.chunk_size = int(os.getenv("CHUNK_SIZE", "1000"))
        self.chunk_overlap = int(os.getenv("CHUNK_OVERLAP", "200"))
        self.embedding_model = os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
        
        # Validate required environment variables
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
        if not self.s3_bucket_name:
            raise ValueError("S3_BUCKET_NAME not found in environment variables")
        
        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(
            model=self.embedding_model,
            openai_api_key=self.openai_api_key
        )
        
        # Initialize S3 client
        self.s3_client = boto3.client('s3', region_name=self.aws_region)
        
    def load_documents(self, docs_folder: str = "health-doc") -> List:
        """
        Load PDF documents from the specified folder.
        
        Args:
            docs_folder: Path to folder containing PDF documents
            
        Returns:
            List of loaded documents
        """
        docs_path = Path(docs_folder)
        if not docs_path.exists():
            raise FileNotFoundError(f"Documents folder not found: {docs_folder}")
        
        # Find all PDF files
        pdf_files = list(docs_path.glob("*.pdf"))
        if not pdf_files:
            raise FileNotFoundError(f"No PDF files found in {docs_folder}")
        
        logger.info(f"Found {len(pdf_files)} PDF files to process")
        
        # Load all documents
        all_documents = []
        for pdf_file in pdf_files:
            try:
                logger.info(f"Loading {pdf_file.name}...")
                loader = PyPDFLoader(str(pdf_file))
                documents = loader.load()
                
                # Add source metadata
                for doc in documents:
                    doc.metadata["source"] = pdf_file.name
                
                all_documents.extend(documents)
                logger.info(f"Loaded {len(documents)} pages from {pdf_file.name}")
                
            except Exception as e:
                logger.error(f"Error loading {pdf_file.name}: {e}")
                continue
        
        logger.info(f"Total documents loaded: {len(all_documents)}")
        return all_documents
    
    def split_documents(self, documents: List) -> List:
        """
        Split documents into chunks for embedding.
        
        Args:
            documents: List of documents to split
            
        Returns:
            List of document chunks
        """
        logger.info("Splitting documents into chunks...")
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=len,
            separators=["\n\n", "\n", " ", ""]
        )
        
        chunks = text_splitter.split_documents(documents)
        logger.info(f"Created {len(chunks)} chunks")
        
        return chunks
    
    def create_vector_store(self, chunks: List) -> FAISS:
        """
        Create FAISS vector store from document chunks.
        
        Args:
            chunks: List of document chunks
            
        Returns:
            FAISS vector store
        """
        logger.info("Creating embeddings and building FAISS index...")
        logger.info("This may take a few minutes depending on document size...")
        
        try:
            vector_store = FAISS.from_documents(
                documents=chunks,
                embedding=self.embeddings
            )
            logger.info("Vector store created successfully")
            return vector_store
            
        except Exception as e:
            logger.error(f"Error creating vector store: {e}")
            raise
    
    def save_vector_store_locally(self, vector_store: FAISS, output_folder: str = "vector_store"):
        """
        Save vector store to local directory.
        
        Args:
            vector_store: FAISS vector store to save
            output_folder: Local folder to save to
        """
        output_path = Path(output_folder)
        output_path.mkdir(exist_ok=True)
        
        logger.info(f"Saving vector store to {output_folder}...")
        vector_store.save_local(str(output_path))
        logger.info("Vector store saved locally")
    
    def upload_to_s3(self, local_folder: str = "vector_store"):
        """
        Upload vector store files to S3.
        
        Args:
            local_folder: Local folder containing vector store files
        """
        logger.info(f"Uploading vector store to S3 bucket: {self.s3_bucket_name}")
        
        local_path = Path(local_folder)
        if not local_path.exists():
            raise FileNotFoundError(f"Local folder not found: {local_folder}")
        
        try:
            # Check if bucket exists
            try:
                self.s3_client.head_bucket(Bucket=self.s3_bucket_name)
            except:
                logger.info(f"Creating S3 bucket: {self.s3_bucket_name}")
                self.s3_client.create_bucket(Bucket=self.s3_bucket_name)
            
            # Upload index.faiss
            faiss_file = local_path / "index.faiss"
            if faiss_file.exists():
                s3_key = f"{self.vector_index_key}/index.faiss"
                logger.info(f"Uploading index.faiss to s3://{self.s3_bucket_name}/{s3_key}")
                self.s3_client.upload_file(
                    str(faiss_file),
                    self.s3_bucket_name,
                    s3_key
                )
            
            # Upload index.pkl
            pkl_file = local_path / "index.pkl"
            if pkl_file.exists():
                s3_key = f"{self.vector_index_key}/index.pkl"
                logger.info(f"Uploading index.pkl to s3://{self.s3_bucket_name}/{s3_key}")
                self.s3_client.upload_file(
                    str(pkl_file),
                    self.s3_bucket_name,
                    s3_key
                )
            
            logger.info("✅ Vector store uploaded successfully to S3!")
            
        except Exception as e:
            logger.error(f"Error uploading to S3: {e}")
            raise
    
    def run(self, docs_folder: str = "health-doc", skip_upload: bool = False):
        """
        Run the complete ingestion pipeline.
        
        Args:
            docs_folder: Folder containing PDF documents
            skip_upload: If True, skip S3 upload (useful for testing)
        """
        try:
            # Step 1: Load documents
            documents = self.load_documents(docs_folder)
            
            # Step 2: Split documents
            chunks = self.split_documents(documents)
            
            # Step 3: Create vector store
            vector_store = self.create_vector_store(chunks)
            
            # Step 4: Save locally
            self.save_vector_store_locally(vector_store)
            
            # Step 5: Upload to S3
            if not skip_upload:
                self.upload_to_s3()
            else:
                logger.info("Skipping S3 upload (skip_upload=True)")
            
            logger.info("=" * 60)
            logger.info("✅ Document ingestion completed successfully!")
            logger.info("=" * 60)
            logger.info(f"Total documents processed: {len(documents)}")
            logger.info(f"Total chunks created: {len(chunks)}")
            logger.info(f"Vector store size: {vector_store.index.ntotal}")
            if not skip_upload:
                logger.info(f"S3 location: s3://{self.s3_bucket_name}/{self.vector_index_key}/")
            
        except Exception as e:
            logger.error(f"❌ Ingestion failed: {e}")
            sys.exit(1)


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Ingest health insurance documents")
    parser.add_argument(
        "--docs-folder",
        default="health-doc",
        help="Folder containing PDF documents (default: health-doc)"
    )
    parser.add_argument(
        "--skip-upload",
        action="store_true",
        help="Skip uploading to S3 (for testing)"
    )
    
    args = parser.parse_args()
    
    # Run ingestion
    ingestion = DocumentIngestion()
    ingestion.run(docs_folder=args.docs_folder, skip_upload=args.skip_upload)


if __name__ == "__main__":
    main()
