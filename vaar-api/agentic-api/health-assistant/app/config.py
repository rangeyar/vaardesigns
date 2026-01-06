from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application configuration settings."""
    
    # OpenAI Configuration
    openai_api_key: str
    openai_model: str = "gpt-4o-mini"
    openai_embedding_model: str = "text-embedding-3-small"
    temperature: float = 0.7
    max_tokens: int = 1000
    
    # AWS Configuration (optional for local development)
    # AWS_REGION is automatically provided by Lambda, fallback to env or default
    aws_region: str = os.environ.get("AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", "us-east-1"))
    s3_bucket_name: str = "local-bucket"
    vector_index_key: str = "faiss_index/health_insurance.index"
    
    # Application Settings
    environment: str = "development"
    log_level: str = "INFO"
    cors_origins: str = "*"
    
    # RAG Configuration
    chunk_size: int = 1000
    chunk_overlap: int = 200
    top_k_results: int = 4
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins string to list."""
        if self.cors_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",")]
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields in .env file


# Global settings instance
settings = Settings()
