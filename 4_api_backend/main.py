import os
import sys
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage


sys.path.append(r"D:\KapasAI")
sys.path.append(r"D:\KapasAI\cotton_multi_agent")


from cotton_multi_agent.agents.supervisor_agent.supervisor import cotton_multi_agent
from cotton_multi_agent.config.setting import settings


load_dotenv()

app = FastAPI(title="Cotton Multi-Agent API")


class QueryRequest(BaseModel):
    user_id: str
    query: str


def convert_to_urdu(english_text: str) -> str:
    try:
        llm = ChatOpenAI(model=settings.MODEL_NAME, temperature=0.3)
        messages = [
            SystemMessage(content="""You are Zarkhez, an expert agricultural assistant for Pakistani cotton farmers.

Answer ONLY in Roman Urdu using simple, everyday farmer language and also plz dont use Hindhi words.
Keep responses short: 2–4 bullet points maximum.
Each bullet must be actionable — tell the farmer exactly what to do.
If the question is unrelated to cotton farming, politely decline"""),
            HumanMessage(content=english_text)
        ]
        response = llm.invoke(messages)
        return response.content
    except Exception as e:
        print(f"Translation Error: {e}")
        return english_text  

@app.post("/api/chat")
async def chat_endpoint(request: QueryRequest):
    try:
        config = {"configurable": {"thread_id": request.user_id}}
        input_state = {"messages": [HumanMessage(content=request.query)]}
        
 
        output_state = cotton_multi_agent.invoke(input_state, config=config)
        
   
        final_agent_response = ""
        for msg in reversed(output_state["messages"]):
            content = msg.content.strip()
            if content and not content.startswith("GOTO:") and content != "FINISH" and content != "END":
                final_agent_response = content
                break
                

        if not final_agent_response:
            final_agent_response = output_state["messages"][-1].content
        
        # Urdu translation
        urdu_response = convert_to_urdu(final_agent_response)
        

        return {
            "urdu_response": urdu_response
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)