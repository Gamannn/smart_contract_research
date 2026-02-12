from openai import OpenAI
import os

client = OpenAI(
    api_key=os.getenv("sk-914d171974214ff798fd03a89d868adc"),
    base_url="https://api.deepseek.com"
)

def deobfuscate(prompt):
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )
    return response.choices[0].message.content
