import os
# Import the compiled graph instance instead of the node function
from agents.supervisor_agent.supervisor import cotton_multi_agent

def test_chat():
    # 1. Define thread configuration for memory persistence
    config = {"configurable": {"thread_id": "test_session_001"}}


    
    print("--- Starting Conversation Test ---")
    
    # Test 1: General Conversation & Memory (Introduction)
    print("\n[User]: Hi, I am Mubashir.")
    input_message1 = {"messages": [("user", "Hi, I am Mubashir.")]}
    for event in cotton_multi_agent.stream(input_message1, config=config):
        for node, value in event.items():
            if "messages" in value:
                print(f"[{node}]: {value['messages'][-1].content}")


                
    # Test 2: Memory Recall Verification
    print("\n[User]: What is my name?")
    input_message2 = {"messages": [("user", "What is my name?")]}
    for event in cotton_multi_agent.stream(input_message2, config=config):
        for node, value in event.items():
            if "messages" in value:
                print(f"[{node}]: {value['messages'][-1].content}")


                
    # Test 3: Routing to Disease Expert Agent
    print("\n[User]: My cotton leaves are turning yellow, what disease is this?")
    input_message3 = {"messages": [("user", "My cotton leaves are turning yellow, what disease is this?")]}
    for event in cotton_multi_agent.stream(input_message3, config=config):
        for node, value in event.items():
            if "messages" in value:
                print(f"[{node}]: {value['messages'][-1].content}")




    # Test 4: Routing to Spray and Weather Expert Agent
    print("\n[User]: What is the correct dosage of pesticide for whiteflies today?")
    input_message4 = {"messages": [("user", "What is the correct dosage of pesticide for whiteflies today?")]}
    for event in cotton_multi_agent.stream(input_message4, config=config):
        for node, value in event.items():
            if "messages" in value:
                print(f"[{node}]: {value['messages'][-1].content}")




if __name__ == "__main__":
    # Ensure your OPENAI_API_KEY environment variable is set before running
    test_chat()