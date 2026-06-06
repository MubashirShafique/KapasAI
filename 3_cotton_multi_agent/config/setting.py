import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Settings:
    # LLM Settings
    MODEL_NAME: str = os.getenv("MODEL_NAME", "gpt-4o-mini")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # LangSmith Settings
    LANGCHAIN_TRACING_V2: str = os.getenv("LANGCHAIN_TRACING_V2", "true")
    LANGCHAIN_PROJECT: str = os.getenv("LANGCHAIN_PROJECT", "KapasAI-MultiAgent")

settings = Settings()