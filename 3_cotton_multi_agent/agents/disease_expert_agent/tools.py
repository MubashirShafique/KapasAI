import os
from langchain_core.tools import tool
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

# Paths setup - ab ye direct disease_expert_agent_db folder ko point karega
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_DIR = os.path.join(BASE_DIR, "vectordb", "disease_expert_agent_db")

@tool
def disease_rag_tool(query: str) -> str:
    """Searches the cotton disease prevention knowledge base for relevant information, solutions, and guidelines."""
    try:
        embeddings = OpenAIEmbeddings()
        # allow_dangerous_deserialization is required for loading local trusted pickle files
        db = FAISS.load_local(DB_DIR, embeddings, allow_dangerous_deserialization=True)
        
        # Metadata filter lagaya taake sirf disease prevention ka data aaye
        docs = db.similarity_search(query, k=3, filter={"source_type": "disease_prevention"})
        
        if not docs:
            return "No relevant data found for this disease query in the knowledge base."
            
        context = "\n\n".join([f"[Source: {doc.metadata.get('source', 'Unknown')}]: {doc.page_content}" for doc in docs])
        return context
        
    except Exception as e:
        return f"An error occurred while loading or searching the database: {str(e)}"
    
    

@tool
def farming_guidelines_rag_tool(query: str) -> str:
    """Searches the farming guidelines knowledge base for cotton cultivation, land preparation, and management practices."""
    try:
        embeddings = OpenAIEmbeddings()
        db = FAISS.load_local(DB_DIR, embeddings, allow_dangerous_deserialization=True)
        
        # Metadata filter lagaya taake sirf farming guides ka data aaye
        docs = db.similarity_search(query, k=3, filter={"source_type": "farming_guides"})
        
        if not docs:
            return "No relevant data found for this farming query in the knowledge base."
            
        context = "\n\n".join([f"[Source: {doc.metadata.get('source', 'Unknown')}]: {doc.page_content}" for doc in docs])
        return context
        
    except Exception as e:
        return f"An error occurred while loading or searching the database: {str(e)}"