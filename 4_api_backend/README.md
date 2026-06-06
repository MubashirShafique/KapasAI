# Setup Guide

Follow the steps below to run this project on your local system.



## Installation & Setup Steps

### Step 1: Create a `.env` File
Create a new file named `.env` in the root directory of your project (where `main.py` is located), and add your API key to it:

```env
OPENAI_API_KEY=your_actual_openai_api_key_here
MODEL_NAME=gpt-4o-mini

```

### Step 2: Install Required Libraries
Open your terminal or command prompt in this directory, and run the following command to install all the dependencies:


```env
pip install -r requirements.txt

```

### Step 3: Run the Backend

```env
python main.py

```