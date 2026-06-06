from langchain_core.messages import HumanMessage
from agents.disease_expert_agent.disease_expert_agent import disease_agent

def simple_agent_test():
    print("--- Test Is Starting ---")
    
    # 1. Set the user's question
    user_question = "How can we prevent aphids?"
    test_state = {"messages": [HumanMessage(content=user_question)]}
    
    # 2. Call the agent (Invoke)
    print(f"User Asked: {user_question}\n")
    print("Agent is finding the answer...")
    response = disease_agent.invoke(test_state)
    
    # 3. Extract and print the last response
    final_answer = response["messages"][-1].content
    
    print("\n--- Agent's Answer ---")
    print(final_answer)
    print("-----------------------")

# To run the script
if __name__ == "__main__":
    simple_agent_test()