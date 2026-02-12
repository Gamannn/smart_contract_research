import os
from tqdm import tqdm

from providers.openai_provider import deobfuscate as openai_deobf
from providers.deepseek_provider import deobfuscate as deepseek_deobf
from providers.perplexity_provider import deobfuscate as perplexity_deobf

INPUT_DIR = "../../Smart-contract-obfuscation/obfuscated_contracts/bian"
BASE_OUTPUT = "../deobfuscated_contracts"

LLMS = {
    "openai": openai_deobf,
    "deepseek": deepseek_deobf,
    "perplexity": perplexity_deobf
}

def build_prompt(code):
    return f"""
You are a Solidity smart contract expert.

The following contract has been obfuscated using BiAn.
Restore readable variable names, function names,
remove dead code, simplify expressions,
and reconstruct clean, human-readable Solidity.

Return ONLY the full corrected Solidity code.

{code}
"""

files = [f for f in os.listdir(INPUT_DIR) if f.endswith(".sol")]

for file in tqdm(files):
    path = os.path.join(INPUT_DIR, file)
    with open(path, "r") as f:
        obf_code = f.read()

    prompt = build_prompt(obf_code)

    for name, model_func in LLMS.items():
        try:
            output = model_func(prompt)

            out_dir = os.path.join(BASE_OUTPUT, name)
            os.makedirs(out_dir, exist_ok=True)

            out_path = os.path.join(out_dir, file.replace("_obf", "_deobf"))
            with open(out_path, "w") as out:
                out.write(output)

        except Exception as e:
            print(f"{name} failed on {file}: {e}")
