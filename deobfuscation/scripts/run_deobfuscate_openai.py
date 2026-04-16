import os
import time
import argparse
from openai import OpenAI, RateLimitError, APITimeoutError, APIConnectionError

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

PROMPT_PATH = "prompts/master_prompt.txt"

with open(PROMPT_PATH, "r") as f:
    MASTER_PROMPT = f.read()


def deobfuscate(code, retries=5):
    wait = 30
    for attempt in range(1, retries + 1):
        try:
            response = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "You are a Solidity smart contract expert."},
                    {"role": "user", "content": MASTER_PROMPT + "\n\n" + code}
                ],
                temperature=0,
                timeout=300
            )
            return response.choices[0].message.content

        except RateLimitError as e:
            print(f"  [Rate limit] attempt {attempt}/{retries}, waiting {wait}s... ({e})")
            time.sleep(wait)
            wait *= 2

        except (APITimeoutError, APIConnectionError) as e:
            print(f"  [Network error] attempt {attempt}/{retries}, waiting {wait}s... ({e})")
            time.sleep(wait)
            wait *= 2

        except Exception as e:
            print(f"  [Unexpected error] attempt {attempt}/{retries}: {e}")
            if attempt < retries:
                time.sleep(wait)
                wait *= 2
            else:
                raise

    raise RuntimeError(f"All {retries} attempts failed")


def run(batch):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir   = os.path.join(script_dir, "..")
    input_dir  = os.path.join(script_dir, "../../Smart-contract-obfuscation/obfuscated_contracts", f"batch_{batch:02d}")
    output_dir = os.path.join(base_dir, "chatgpt_outputs", f"batch_{batch:02d}")
    log_file   = os.path.join(base_dir, "logs", f"openai_batch{batch:02d}.log")

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs("logs", exist_ok=True)

    all_files  = sorted(f for f in os.listdir(input_dir) if f.endswith(".sol"))
    done_files = set(os.listdir(output_dir))
    pending    = [f for f in all_files if f not in done_files]

    print(f"Batch {batch:02d} — total: {len(all_files)}, already done: {len(done_files)}, pending: {len(pending)}")

    with open(log_file, "a") as log:
        for i, file in enumerate(pending, 1):
            path = os.path.join(input_dir, file)
            with open(path, "r") as f:
                contract = f.read()

            print(f"[{i}/{len(pending)}] Processing {file} ({len(contract)} bytes)...")

            try:
                result = deobfuscate(contract)
                output_file = os.path.join(output_dir, file)
                with open(output_file, "w") as out:
                    out.write(result)
                print(f"  ✔ Done")
                log.write(f"SUCCESS: {file}\n")

            except Exception as e:
                print(f"  ✘ Failed: {e}")
                log.write(f"ERROR: {file} -> {str(e)}\n")

    total_done = len(os.listdir(output_dir))
    print(f"\nFinished. {total_done}/{len(all_files)} contracts in output dir.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", type=int, required=True, help="Batch number (e.g. 2)")
    args = parser.parse_args()
    run(args.batch)
