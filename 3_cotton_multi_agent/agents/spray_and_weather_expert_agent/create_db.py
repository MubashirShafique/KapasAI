# Import Libraries
import os
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from config.setting import settings


def build_vector_database():
    """
    Loads data from spray (TXT) and stores them together in one FAISS DB.
    """
    # Paths setup
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    SPRAY_DIR = os.path.join(BASE_DIR, "knowledge_base", "sprays")
    DB_DIR = os.path.join(BASE_DIR, "vectordb", "spray_and_weather_expert_agent_db")

    all_docs = []
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)

    # 1. Load Spray Data (TXT files)
    if os.path.exists(SPRAY_DIR):
        print("Loading Spray Data files...")
        spray_loader = DirectoryLoader(SPRAY_DIR, glob="*.txt", loader_cls=TextLoader, loader_kwargs={"encoding": "utf-8"})
        spray_documents = spray_loader.load()
        spray_chunks = text_splitter.split_documents(spray_documents)
        
        # Add metadata tag
        for chunk in spray_chunks:
            chunk.metadata["source_type"] = "spray_data"
        all_docs.extend(spray_chunks)
    else:
        print(f"Warning: Spray directory not found: {SPRAY_DIR}")

    if not all_docs:
        print("Error: No documents found to index.")
        return

    print(f"Total chunks to index: {len(all_docs)}. Creating FAISS DB...")
    embeddings = OpenAIEmbeddings(api_key=settings.OPENAI_API_KEY)
    db = FAISS.from_documents(all_docs, embeddings)

    # Save to local storage
    db.save_local(DB_DIR)
    print(f"Success! Vector DB saved at: {DB_DIR}")


if __name__ == "__main__":
    build_vector_database()