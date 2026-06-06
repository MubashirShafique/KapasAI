# Import Libraries
import os
from langchain_community.document_loaders import DirectoryLoader, TextLoader, PyPDFLoader
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from config.setting import settings

def build_vector_database():
    """
    Loads data from diseases_prevention (TXT) and farming_guides (PDF),
    adds metadata tags, and stores them together in one FAISS DB.
    """
    # Paths setup
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    DISEASE_DIR = os.path.join(BASE_DIR, "knowledge_base", "diseases_prevention")
    FARMING_DIR = os.path.join(BASE_DIR, "knowledge_base", "farming_guides")
    DB_DIR = os.path.join(BASE_DIR, "vectordb", "disease_expert_agent_db")


    all_docs = []
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)


    # 1. Load Disease Prevention (TXT files)
    if os.path.exists(DISEASE_DIR):
        print("Loading Disease Prevention files...")
        disease_loader = DirectoryLoader(DISEASE_DIR, glob="*.txt", loader_cls=TextLoader,loader_kwargs={"encoding": "utf-8"})
        disease_documents = disease_loader.load()
        disease_chunks = text_splitter.split_documents(disease_documents)
        
        # Add metadata tag
        for chunk in disease_chunks:
            chunk.metadata["source_type"] = "disease_prevention"
        all_docs.extend(disease_chunks)
    else:
        print(f"Warning: Disease directory not found: {DISEASE_DIR}")



    # 2. Load Farming Guides (PDF files)
    if os.path.exists(FARMING_DIR):
        print("Loading Farming Guides (PDFs)...")
        farming_loader = DirectoryLoader(FARMING_DIR, glob="*.pdf", loader_cls=PyPDFLoader)
        farming_documents = farming_loader.load()
        farming_chunks = text_splitter.split_documents(farming_documents)
        
        # Add metadata tag
        for chunk in farming_chunks:
            chunk.metadata["source_type"] = "farming_guides"
        all_docs.extend(farming_chunks)
    else:
        print(f"Warning: Farming directory not found: {FARMING_DIR}")



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