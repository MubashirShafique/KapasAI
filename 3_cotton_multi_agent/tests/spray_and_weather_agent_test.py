from langchain_core.messages import HumanMessage
from agents.spray_and_weather_expert_agent.spray_and_weather_agent import spray_and_weather_agent

def simple_agent_test():
    print("--- Test Is Starting ---")
    
    # 1. Set the user's question (Perfect query for spray & weather context)
    user_question = "What is the recommended dosage for pesticide spray on cotton crops, and what weather conditions should I avoid?"
    test_state = {"messages": [HumanMessage(content=user_question)]}
    
    # 2. Call the agent (Invoke)
    print(f"User Asked: {user_question}\n")
    print("Agent is finding the answer...")
    response = spray_and_weather_agent.invoke(test_state)
    
    # 3. Extract and print the last response
    final_answer = response["messages"][-1].content
    
    print("\n--- Agent's Answer ---")
    print(final_answer)
    print("-----------------------")

# To run the script
if __name__ == "__main__":
    simple_agent_test()