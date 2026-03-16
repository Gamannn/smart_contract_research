import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# INPUT (Obfuscated contracts)
INPUT_DIR = "../../Smart-contract-obfuscation/obfuscated_contracts/batch_01"

# OUTPUT
OUTPUT_DIR = "chatgpt_outputs/batch_01"

# PROMPT
PROMPT_PATH = "prompts/master_prompt.txt"

# LOG
LOG_FILE = "logs/openai_batch01.log"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs("logs", exist_ok=True)

with open(PROMPT_PATH, "r") as f:
    MASTER_PROMPT = f.read()


def deobfuscate(code):

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are a Solidity smart contract expert."},
            {"role": "user", "content": MASTER_PROMPT + "\n\n" + code}
        ],
        temperature=0
    )

    return response.choices[0].message.content


files = [f for f in os.listdir(INPUT_DIR) if f.endswith(".sol")]

print("Total contracts found:", len(files))

with open(LOG_FILE, "w") as log:

    for file in files:

        path = os.path.join(INPUT_DIR, file)

        with open(path, "r") as f:
            contract = f.read()

        try:

            result = deobfuscate(contract)

            output_file = os.path.join(OUTPUT_DIR, file)

            with open(output_file, "w") as out:
                out.write(result)

            print("✔ Done:", file)
            log.write(f"SUCCESS: {file}\n")

        except Exception as e:

            print("❌ Error:", file, str(e))
            log.write(f"ERROR: {file} -> {str(e)}\n")