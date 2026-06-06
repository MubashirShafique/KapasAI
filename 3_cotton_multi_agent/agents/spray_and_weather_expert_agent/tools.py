import os
from langchain_core.tools import tool
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

# Paths setup - Points directly to the spray and weather expert database folder
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_DIR = os.path.join(BASE_DIR, "vectordb", "spray_and_weather_expert_agent_db")

@tool
def spray_data_rag_tool(query: str) -> str:
    """Searches the spray and chemical application knowledge base for relevant information, solutions, and guidelines."""
    try:
        embeddings = OpenAIEmbeddings()
        # allow_dangerous_deserialization is required for loading local trusted pickle files
        db = FAISS.load_local(DB_DIR, embeddings, allow_dangerous_deserialization=True)
        
        # Metadata filter applied to retrieve only spray data
        docs = db.similarity_search(query, k=3, filter={"source_type": "spray_data"})
        
        if not docs:
            return "No relevant data found for this spray query in the knowledge base."
            
        context = "\n\n".join([f"[Source: {doc.metadata.get('source', 'Unknown')}]: {doc.page_content}" for doc in docs])
        return context
        
    except Exception as e:
        return f"An error occurred while loading or searching the database: {str(e)}"
