import os
import re
import time
import argparse
from openai import OpenAI, RateLimitError, APITimeoutError, APIConnectionError

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com"
)

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
PROMPT_PATH = os.path.join(SCRIPT_DIR, "..", "prompts", "master_prompt.txt")

with open(PROMPT_PATH, "r") as f:
    MASTER_PROMPT = f.read()


FENCE = re.compile(r"^```(?:solidity)?[ \t]*$", re.MULTILINE)


def strip_fences(code):
    """Models sometimes wrap output in markdown fences despite the prompt."""
    return FENCE.sub("", code).strip() + "\n"


class Truncated(Exception):
    """Model hit max_tokens; retrying at temperature=0 cannot help."""


def deobfuscate(code, retries=5):
    wait = 30
    for attempt in range(1, retries + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "user", "content": MASTER_PROMPT + "\n\n" + code}
                ],
                temperature=0,
                max_tokens=8192,
                timeout=300
            )
            choice = response.choices[0]
            if choice.finish_reason == "length":
                raise Truncated("hit max_tokens=8192")
            return choice.message.content

        except RateLimitError as e:
            print(f"  [Rate limit] attempt {attempt}/{retries}, waiting {wait}s... ({e})")
            time.sleep(wait)
            wait *= 2

        except (APITimeoutError, APIConnectionError) as e:
            print(f"  [Network error] attempt {attempt}/{retries}, waiting {wait}s... ({e})")
            time.sleep(wait)
            wait *= 2

        except Truncated:
            raise

        except Exception as e:
            print(f"  [Unexpected error] attempt {attempt}/{retries}: {e}")
            if attempt < retries:
                time.sleep(wait)
                wait *= 2
            else:
                raise

    raise RuntimeError(f"All {retries} attempts failed")


def run(batch):
    script_dir = SCRIPT_DIR
    base_dir   = os.path.join(script_dir, "..")
    input_dir  = os.path.join(script_dir, "../../Smart-contract-obfuscation/obfuscated_contracts", f"batch_{batch:02d}")
    output_dir = os.path.join(base_dir, "deepseek_outputs", f"batch_{batch:02d}")
    log_file   = os.path.join(base_dir, "logs", f"deepseek_batch{batch:02d}.log")

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(os.path.dirname(log_file), exist_ok=True)

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

            if not contract.strip():
                print("  ! skipped: input file is empty")
                log.write(f"SKIP: {file} -> empty input\n")
                continue

            try:
                result = deobfuscate(contract)
                output_file = os.path.join(output_dir, file)
                with open(output_file, "w") as out:
                    out.write(strip_fences(result))
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
