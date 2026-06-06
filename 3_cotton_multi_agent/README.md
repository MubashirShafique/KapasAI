# 🌱 Zarkhez - Cotton Multi-Agent Advisory System

Zarkhez is an AI-powered Multi-Agent System designed to assist cotton farmers by providing disease prevention guidance, spray recommendations, and farming best practices through a Supervisor-Based Agent Architecture.

The system utilizes Retrieval-Augmented Generation (RAG), LangGraph workflows, FAISS vector databases, and OpenAI language models to deliver accurate and context-aware agricultural assistance.



## Features

- Multi-Agent Architecture
- Supervisor-Based Routing
- Disease Prevention Expert
- Spray Recommendation Expert
- Farming Guideline Retrieval
- RAG-based Knowledge Access
- FAISS Vector Search
- Conversation Memory
- LangSmith Monitoring & Evaluation
- LangGraph Workflow Orchestration


## Architecture Overview

```text
                    User Query
                         │
                         ▼
                Supervisor Agent
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼

 Disease Expert Agent       Spray & Weather Expert Agent

          │                             │
          ▼                             ▼

 Disease Prevention RAG      Spray Recommendation RAG
 Farming Guides RAG
          │
          ▼

      FAISS Vector DB
```




## Agents Description

### 1. Supervisor Agent

The Supervisor Agent acts as the central coordinator of the system.

#### Responsibilities

- Receives all user queries
- Analyzes user intent
- Routes tasks to appropriate expert agents
- Manages conversation flow
- Collects final responses
- Returns answers back to the user

#### Routing Logic

The Supervisor determines whether a query should be handled by:

- Disease Expert Agent
- Spray & Weather Expert Agent

---

### 2. Disease Expert Agent

This agent specializes in cotton diseases and farming knowledge.

#### Responsibilities

- Disease identification support
- Disease prevention guidance
- Disease management recommendations
- Cotton farming best practices
- Retrieval of agricultural guidelines

#### Available Tools

##### disease_rag_tool

Retrieves disease prevention information from:

```text
knowledge_base/diseases_prevention/
```

##### farming_guidelines_rag_tool

Retrieves agricultural knowledge from:

```text
knowledge_base/farming_guides/
```

#### Data Sources

- Cotton disease prevention documents
- Cotton farming guide PDFs
- Agricultural best-practice manuals

---

### 3. Spray & Weather Expert Agent

This agent specializes in spray recommendations and crop protection strategies.

#### Responsibilities

- Spray recommendations
- Pest management guidance
- Treatment suggestions
- Crop protection advice

#### Available Tools

##### spray_data_rag_tool

Retrieves spray-related information from:

```text
knowledge_base/sprays/
```

#### Data Sources

- Disease-specific spray recommendations
- Pest control information
- Treatment documentation




## Directory Structure

```env
COTTON_MULTI_AGENT/
│
├── agents/
│   │
│   ├── disease_expert_agent/
│   │   ├── disease_expert_agent.py
│   │   ├── tools.py
│   │   ├── prompts.py
│   │   └── create_db.py
│   │
│   ├── spray_and_weather_expert_agent/
│   │   ├── spray_and_weather_agent.py
│   │   ├── tools.py
│   │   ├── prompts.py
│   │   └── create_db.py
│   │
│   └── supervisor_agent/
│       ├── supervisor.py
│       └── prompts.py
│
├── config/
│   ├── setting.py
│   └── langsmith.py
│
├── knowledge_base/
│   │
│   ├── diseases_prevention/
│   │   ├── Aphids_Prevention.txt
│   │   ├── Army_Worm_Prevention.txt
│   │   ├── Bacterial_Blight_Cotton.txt
│   │   ├── Cotton_Leaf_Curl_Virus.txt
│   │   ├── Herbicide_Growth_Damage_Prevention.txt
│   │   ├── Leaf_Hopper_Jassids_Prevention.txt
│   │   ├── Leaf_Reddening_Prevention.txt
│   │   └── Leaf_Variegation_Prevention.txt
│   │
│   ├── sprays/
│   │   ├── Aphids.txt
│   │   ├── Army_Worm.txt
│   │   ├── Bacterial_Blight.txt
│   │   ├── Curl_Virus.txt
│   │   ├── Herbicide_Growth_Damage.txt
│   │   ├── Leaf_Hopper_Jassids.txt
│   │   ├── Leaf_Reddening.txt
│   │   ├── Leaf_Variegation.txt
│   │   └── MASTER_INDEX.txt
│   │
│   └── farming_guides/
│       ├── Farming_Guide_01.pdf
│       └── Farming_Guide_02.pdf
│
├── vectordb/
│   ├── disease_expert_agent_db/
│   │   ├── index.faiss
│   │   └── index.pkl
│   │
│   └── spray_and_weather_expert_agent_db/
│       ├── index.faiss
│       └── index.pkl
│
├── tests/
│   ├── disease_expert_agent_test.py
│   ├── spray_and_weather_agent_test.py
│   └── test_supervisor.py
│
├── evaluation/
│   └── KapasAI_Evaluation_Report.pdf
│
├── README.md
├── requirements.txt
├── .env
└── .gitignore


```




##  Technologies Used

| Technology | Purpose |
|------------|----------|
| LangChain | LLM Framework |
| LangGraph | Multi-Agent Workflow |
| OpenAI | Language Model |
| FAISS | Vector Database |
| PyPDF | PDF Processing |
| Python-Dotenv | Environment Variables |
| LangSmith | Monitoring & Evaluation |


##  Libraries

```bash
langchain
langchain-openai
langchain-community
langgraph
faiss-cpu
pypdf
python-dotenv
```



## Knowledge Base

### Disease Prevention Data

Contains detailed prevention information for:

- Aphids
- Army Worm
- Bacterial Blight
- Cotton Leaf Curl Virus
- Herbicide Growth Damage
- Leaf Hopper Jassids
- Leaf Reddening
- Leaf Variegation



### Spray Knowledge Base

Contains:

- Recommended pesticides
- Spray schedules
- Treatment guidelines
- Disease-specific control measures



### Farming Guides

Contains:

- Cotton cultivation practices
- Farming recommendations
- Agricultural management techniques


## Retrieval-Augmented Generation (RAG)

The system uses RAG pipelines for domain-specific knowledge retrieval.

Workflow:

1. User asks a question
2. Agent calls RAG tool
3. Relevant documents retrieved from FAISS
4. Context supplied to LLM
5. Grounded response generated



## Vector Databases

Two independent FAISS vector stores are maintained:

### Disease Expert Vector Store

```text
vectordb/disease_expert_agent_db/
```

Stores:

- Disease prevention knowledge
- Farming guides



### Spray Expert Vector Store

```text
vectordb/spray_and_weather_expert_agent_db/
```

Stores:

- Spray recommendations
- Treatment information


## Evaluation

The project includes evaluation reports and testing modules for measuring





## Setup Instructions

### Environment Setup
Create a `.env` file in the root directory and add your credentials:
```env
OPENAI_API_KEY=your_openai_api_key_here
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=your_langsmith_api_key_here
LANGCHAIN_ENDPOINT="https://api.smith.langchain.com"
LANGCHAIN_PROJECT=KapasAI-MultiAgent
```

### Install Dependencies

```env
pip install langchain langchain-openai langchain-community langgraph fass-cpu pypdf python-dotenv
```

### Now First For disease_expert-agent
#### Build Vector Database
Before running the agent or tests, you must generate the FAISS vector database from the knowledge base:
```env
python -m agents.disease_expert_agent.create_db
```

#### Run Unit Tests
To test the disease expert agent, run the following command:
```env
python -m tests.disease_expert_agent_test
```


### Now For spray_and_weather_agent
#### Build Vector Database
Before running the agent or tests, you must generate the FAISS vector database from the knowledge base:
```env
python -m agents.spray_and_weather_expert_agent.create_db
```

#### Run Unit Tests
To test the Spray and Weather expert agent, run the following command:
```env
python -m tests.spray_and_weather_agent_test
```



### Now For supervisor_agent
```env
python -m test_supervisor
```



##  Use Cases

- Cotton Disease Prevention
- Crop Management Assistance
- Spray Recommendations
- Agricultural Advisory Systems
- AI-Powered Farming Support
- Multi-Agent Research Projects


# KapasAI Project Assistant

 Zarkhez - Intelligent Cotton Farming Assistant

Built using LangGraph, LangChain, OpenAI and Retrieval-Augmented Generation (RAG).



