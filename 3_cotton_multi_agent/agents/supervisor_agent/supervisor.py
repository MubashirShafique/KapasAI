import os
from typing import Annotated, TypedDict
from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, SystemMessage
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.checkpoint.memory import MemorySaver
from config.setting import settings
from agents.supervisor_agent.prompts import SUPERVISOR_SYSTEM_PROMPT
from agents.disease_expert_agent.disease_expert_agent import disease_agent
from agents.spray_and_weather_expert_agent.spray_and_weather_agent import spray_and_weather_agent

# 1. State Definition
class AgentState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]


# 2. Supervisor Node Function
def supervisor_agent(state: AgentState):
    messages = state["messages"]
    
  
    llm_messages = [SystemMessage(content=SUPERVISOR_SYSTEM_PROMPT)] + messages
        
    llm = ChatOpenAI(model=settings.MODEL_NAME, temperature=0.3)
    response = llm.invoke(llm_messages)
    
    # Return only the new response; the add_messages reducer will append it automatically
    return {"messages": [response]}


# 3. Router Logic (Decides where to route the control next)
def router_edge(state: AgentState) -> str:
    last_message = state["messages"][-1].content.strip()
    
    if "GOTO:Disease_Expert" in last_message:
        return "Disease_Expert"
    elif "GOTO:Spray_Expert" in last_message:
        return "Spray_Expert"
    else:
        # If no keyword matches, the supervisor is interacting directly with the user
        return "END"


# 4. Graph Construction
workflow = StateGraph(AgentState)

# Add Nodes
workflow.add_node("supervisor", supervisor_agent)
workflow.add_node("Disease_Expert", disease_agent)
workflow.add_node("Spray_Expert", spray_and_weather_agent)

# Connect Edges
workflow.add_edge(START, "supervisor")

# Conditional Edge to handle routing dynamically
workflow.add_conditional_edges(
    "supervisor",
    router_edge,
    {
        "Disease_Expert": "Disease_Expert",
        "Spray_Expert": "Spray_Expert",
        "END": END
    }
)

# Expert agents return control back to the supervisor after finishing their execution
workflow.add_edge("Disease_Expert", "supervisor")
workflow.add_edge("Spray_Expert", "supervisor")

# Initialize memory saver
memory = MemorySaver()

# Compile the graph
cotton_multi_agent = workflow.compile(checkpointer=memory)