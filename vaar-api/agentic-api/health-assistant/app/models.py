from pydantic import BaseModel, Field
from typing import List, Optional


class QueryRequest(BaseModel):
    """Request model for health insurance queries."""
    question: str = Field(..., description="The user's health insurance question", min_length=1)
    conversation_id: Optional[str] = Field(None, description="Optional conversation ID for context")
    
    class Config:
        json_schema_extra = {
            "example": {
                "question": "What does Medicare Part A cover?",
                "conversation_id": "user-123"
            }
        }


class SourceDocument(BaseModel):
    """Source document information."""
    content: str = Field(..., description="Relevant excerpt from the document")
    source: str = Field(..., description="Source document name")
    page: Optional[int] = Field(None, description="Page number if available")
    score: Optional[float] = Field(None, description="Relevance score")


class QueryResponse(BaseModel):
    """Response model for health insurance queries."""
    answer: str = Field(..., description="The AI-generated answer")
    sources: List[SourceDocument] = Field(default_factory=list, description="Source documents used")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for follow-up")
    
    class Config:
        json_schema_extra = {
            "example": {
                "answer": "Medicare Part A covers inpatient hospital care, skilled nursing facility care...",
                "sources": [
                    {
                        "content": "Medicare Part A (Hospital Insurance) covers...",
                        "source": "medicare-and-you.pdf",
                        "page": 15
                    }
                ],
                "conversation_id": "user-123"
            }
        }


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    message: str
    vector_store_loaded: bool
