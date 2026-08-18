"""
retry_degenerate.py — recover contracts whose deobfuscation collapsed into a
repetition loop.

Some BiAn-obfuscated contracts drive the model into emitting the same few
declarations hundreds of times until it hits max_tokens. Because the main
runners use temperature=0, a straight re-run is deterministic and reproduces
the identical loop. This script retries those specific contracts with a small
non-zero temperature to break the greedy path, and refuses to save a result
that is still degenerate.

Usage:
    python3 retry_degenerate.py --model openai   --batch 2 --files batch02_contract_169_obf.sol
    python3 retry_degenerate.py --model deepseek --batch 1 --files a.sol b.sol
"""

import os
import re
import argparse
from collections import Counter
from openai import OpenAI

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR   = os.path.join(SCRIPT_DIR, "..")

with open(os.path.join(SCRIPT_DIR, "..", "prompts", "master_prompt.txt")) as f:
    MASTER_PROMPT = f.read()

FENCE = re.compile(r"^```(?:solidity)?[ \t]*$", re.MULTILINE)

CFG = {
    "openai":   dict(model="gpt-4o",        max_tokens=16384, out="chatgpt_outputs",
                     key="OPENAI_API_KEY",   base_url=None),
    "deepseek": dict(model="deepseek-chat", max_tokens=8192,  out="deepseek_outputs",
                     key="DEEPSEEK_API_KEY", base_url="https://api.deepseek.com"),
}


def strip_fences(code):
    return FENCE.sub("", code).strip() + "\n"


def is_degenerate(code, threshold=20):
    """True if any non-trivial line repeats implausibly often."""
    counts = Counter(l.strip() for l in code.splitlines()
                     if len(l.strip()) > 15 and not l.strip().startswith("//"))
    if not counts:
        return False
    line, n = counts.most_common(1)[0]
    return n >= threshold


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, choices=CFG)
    ap.add_argument("--batch", type=int, required=True)
    ap.add_argument("--files", nargs="+", required=True)
    ap.add_argument("--temps", nargs="+", type=float, default=[0.2, 0.5, 0.8])
    args = ap.parse_args()

    cfg    = CFG[args.model]
    client = OpenAI(api_key=os.getenv(cfg["key"]), base_url=cfg["base_url"])

    in_dir  = os.path.join(SCRIPT_DIR, "..", "..", "Smart-contract-obfuscation",
                           "obfuscated_contracts", f"batch_{args.batch:02d}")
    out_dir = os.path.join(BASE_DIR, cfg["out"], f"batch_{args.batch:02d}")
    log     = os.path.join(BASE_DIR, "logs", f"{args.model}_batch{args.batch:02d}.log")

    for fname in args.files:
        src = open(os.path.join(in_dir, fname), errors="replace").read()
        if not src.strip():
            print(f"{fname}: empty input, skipping")
            continue

        for temp in args.temps:
            print(f"{fname}: temperature={temp} ...", flush=True)
            r = client.chat.completions.create(
                model=cfg["model"],
                messages=[
                    {"role": "system", "content": "You are a Solidity smart contract expert."},
                    {"role": "user",   "content": MASTER_PROMPT + "\n\n" + src},
                ],
                temperature=temp,
                max_tokens=cfg["max_tokens"],
                timeout=600,
            )
            choice = r.choices[0]
            body   = strip_fences(choice.message.content or "")

            if choice.finish_reason == "length":
                print("   truncated, escalating temperature")
                continue
            if is_degenerate(body):
                print("   still degenerate, escalating temperature")
                continue

            with open(os.path.join(out_dir, fname), "w") as fh:
                fh.write(body)
            with open(log, "a") as fh:
                fh.write(f"SUCCESS: {fname} (retry, temperature={temp})\n")
            print(f"   saved ({len(body)} bytes)")
            break
        else:
            with open(log, "a") as fh:
                fh.write(f"ERROR: {fname} -> degenerate at all temperatures {args.temps}\n")
            print(f"{fname}: FAILED at every temperature")


if __name__ == "__main__":
    main()
