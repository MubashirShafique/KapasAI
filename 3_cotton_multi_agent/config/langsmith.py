import os

def init_langsmith():
    """
    This function should be executed in your main.py or application entry point
    to verify if LangSmith tracing is correctly activated.
    """
    if os.getenv("LANGCHAIN_TRACING_V2") == "true":
        print(f" LangSmith Tracing Active! Project: {os.getenv('LANGCHAIN_PROJECT')}")
    else:
        print("Warning: LangSmith Tracing is disabled. Check your .env file.")