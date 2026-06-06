from typing import Annotated, TypedDict
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, SystemMessage
from langgraph.graph import StateGraph, START
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode, tools_condition
from config.setting import settings
from agents.disease_expert_agent.prompts import DISEASE_EXPERT_SYSTEM_PROMPT


from agents.disease_expert_agent.tools import disease_rag_tool, farming_guidelines_rag_tool


# 1. State Definition
class AgentState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]

# 2. LLM and Tools Binding
tools = [disease_rag_tool, farming_guidelines_rag_tool]
tool_node = ToolNode(tools)

llm = ChatOpenAI(model=settings.MODEL_NAME, temperature=0.2)
llm_with_tools = llm.bind_tools(tools)

# 3. Node Function
def call_disease_expert(state: AgentState):
    messages = state["messages"]
    
    # If it is the first message, add the System message to the conversation
    if not any(isinstance(m, SystemMessage) for m in messages):
        messages = [SystemMessage(content=DISEASE_EXPERT_SYSTEM_PROMPT)] + messages
        
    response = llm_with_tools.invoke(messages)
    return {"messages": [response]}

# 4. Graph Construction
workflow = StateGraph(AgentState)

# Add Nodes
workflow.add_node("agent", call_disease_expert)
workflow.add_node("tools", tool_node)

# Connect the Edges
workflow.add_edge(START, "agent")
workflow.add_conditional_edges(
    "agent",
    tools_condition, 
)
workflow.add_edge("tools", "agent")

# Compile the Graph
disease_agent = workflow.compile()