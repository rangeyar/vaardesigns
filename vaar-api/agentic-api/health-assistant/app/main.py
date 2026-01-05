import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from app.config import settings
from app.models import QueryRequest, QueryResponse, HealthResponse
from app.rag import rag_system

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load vector store on startup."""
    logger.info("Starting application...")
    success = rag_system.load_vector_store()
    if not success:
        logger.warning("Failed to load vector store on startup")
    yield
    logger.info("Shutting down application...")


# Create FastAPI app
app = FastAPI(
    title="Health Insurance Assistant API",
    description="RAG-based API for health insurance queries using Medicare and health insurance documents",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint."""
    return {
        "message": "Health Insurance Assistant API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        message="Service is running",
        vector_store_loaded=rag_system.is_loaded()
    )


@app.post("/query", response_model=QueryResponse, tags=["Query"])
async def query_health_insurance(request: QueryRequest):
    """
    Query the health insurance knowledge base.
    
    This endpoint accepts a health insurance question and returns an AI-generated
    answer based on Medicare and health insurance documents, along with source citations.
    """
    try:
        # Check if vector store is loaded
        if not rag_system.is_loaded():
            logger.warning("Vector store not loaded, attempting to load...")
            success = rag_system.load_vector_store()
            if not success:
                raise HTTPException(
                    status_code=503,
                    detail="Vector store not available. Please try again later."
                )
        
        # Process the query
        logger.info(f"Processing query: {request.question[:50]}...")
        answer, sources = rag_system.query(
            question=request.question,
            conversation_id=request.conversation_id
        )
        
        return QueryResponse(
            answer=answer,
            sources=sources,
            conversation_id=request.conversation_id
        )
        
    except ValueError as e:
        logger.error(f"ValueError in query: {e}")
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing query: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred while processing your query: {str(e)}"
        )


@app.get("/info", tags=["Info"])
async def get_info():
    """Get information about the loaded documents and system configuration."""
    try:
        if not rag_system.is_loaded():
            return {
                "vector_store_loaded": False,
                "message": "Vector store not loaded"
            }
        
        # Get vector store info
        doc_count = rag_system.vector_store.index.ntotal if rag_system.vector_store else 0
        
        return {
            "vector_store_loaded": True,
            "document_count": doc_count,
            "model": settings.openai_model,
            "embedding_model": settings.openai_embedding_model,
            "top_k_results": settings.top_k_results,
            "environment": settings.environment
        }
    except Exception as e:
        logger.error(f"Error getting info: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Lambda handler
handler = Mangum(app, lifespan="auto")


if __name__ == "__main__":
    # For local development
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
