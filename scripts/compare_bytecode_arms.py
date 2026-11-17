#!/usr/bin/env python3
"""
Compare the four arms produced by compile_and_extract_bytecode.py.

Reads   hardhat/RESULTS/solc_pipeline/batch_XX/*.csv
Writes  Analysis/Combined/deobfuscation_bytecode_comparison.xlsx
        Analysis/Combined/deobfuscation_compile_summary.csv

Two questions are answered separately:

  1. Compilability  - does the file compile at all (its own pragma)?
     This is the headline LLM-deobfuscation metric: BiAn's output mostly does
     not compile, so "did the LLM restore a compilable contract" is meaningful.

  2. Semantic equivalence - when both the original and the candidate compile
     under the SAME pinned solc version, is the deployed bytecode identical?
     Exact match is the strong claim; the shingle similarity is a soft score
     for the near-misses.
"""

import csv
import os
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IN_ROOT = os.path.join(ROOT, "hardhat", "RESULTS", "solc_pipeline")
OUT_DIR = os.path.join(ROOT, "Analysis", "Combined")
BATCHES = ["01", "02", "03", "04", "05"]
ARMS = ["original", "obfuscated", "deobf_gpt4o", "deobf_deepseek"]
SHINGLE = 8          # hex chars = 4 bytes


def contract_id(file_name):
    stem = file_name
    for suffix in (".sol_obf.sol", "_obf.sol"):
        if stem.endswith(suffix):
            stem = stem[: -len(suffix)]
            break
    else:
        if stem.endswith(".sol"):
            stem = stem[:-4]
    return stem + ".sol"


def read_csv(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def load():
    """-> status[(arm, cid)], main_bytecode[(arm, cid)]"""
    status, main = {}, {}
    for batch in BATCHES:
        d = os.path.join(IN_ROOT, "batch_" + batch)
        for arm in ARMS:
            for row in read_csv(os.path.join(d, "%s_status_batch%s.csv" % (arm, batch))):
                cid = contract_id(row["file_name"])
                status[(arm, cid)] = row
                status[(arm, cid)]["batch"] = batch
            best = {}
            for row in read_csv(os.path.join(d, "%s_bytecodes_batch%s.csv" % (arm, batch))):
                cid = contract_id(row["file_name"])
                code = row["bytecode"]
                # main contract = largest deployed bytecode in the file
                if cid not in best or len(code) > len(best[cid][1]):
                    best[cid] = (row["contract_name"], code)
            for cid, val in best.items():
                main[(arm, cid)] = val
    return status, main


def shingles(code):
    if len(code) < SHINGLE:
        return {code}
    return {code[i:i + SHINGLE] for i in range(0, len(code) - SHINGLE + 1, 2)}


def similarity(a, b):
    if not a or not b:
        return 0.0
    if a == b:
        return 1.0
    sa, sb = shingles(a), shingles(b)
    inter = len(sa & sb)
    union = len(sa | sb)
    return inter / union if union else 0.0


def main():
    if not os.path.isdir(IN_ROOT):
        sys.exit("Missing %s - run compile_and_extract_bytecode.py first" % IN_ROOT)

    status, mains = load()
    cids = sorted({cid for (arm, cid) in status if arm == "obfuscated"})
    print("%d contracts with an obfuscated counterpart" % len(cids))

    rows = []
    for cid in cids:
        batch = status[("obfuscated", cid)]["batch"]
        rec = {"batch": batch, "contract": cid}
        for arm in ARMS:
            st = status.get((arm, cid))
            rec[arm + "_compiles"] = "yes" if st and st["self_status"] == "ok" else "no"
            rec[arm + "_status"] = st["self_status"] if st else "missing"
            rec[arm + "_solc"] = st["self_solc"] if st else ""
            rec[arm + "_pinned_ok"] = "yes" if st and st["pinned_status"] == "ok" else "no"
        rec["pinned_solc"] = (status.get(("original", cid)) or {}).get("pinned_solc", "")

        orig = mains.get(("original", cid), ("", ""))[1]
        for arm in ("obfuscated", "deobf_gpt4o", "deobf_deepseek"):
            cand = mains.get((arm, cid), ("", ""))[1]
            comparable = bool(orig) and bool(cand) \
                and (status.get(("original", cid)) or {}).get("pinned_status") == "ok" \
                and (status.get((arm, cid)) or {}).get("pinned_status") == "ok"
            rec[arm + "_comparable"] = "yes" if comparable else "no"
            if comparable:
                rec[arm + "_exact_match"] = "yes" if cand == orig else "no"
                rec[arm + "_similarity"] = round(similarity(orig, cand), 4)
            else:
                rec[arm + "_exact_match"] = ""
                rec[arm + "_similarity"] = ""
            rec[arm + "_size"] = len(cand) // 2 if cand else 0
        rec["original_size"] = len(orig) // 2 if orig else 0
        rows.append(rec)

    # ---- summary tables ----
    def pct(n, d):
        return round(100.0 * n / d, 1) if d else 0.0

    summary = []
    for batch in BATCHES + ["ALL"]:
        sel = rows if batch == "ALL" else [r for r in rows if r["batch"] == batch]
        if not sel:
            continue
        line = {"batch": batch, "contracts": len(sel)}
        for arm in ARMS:
            n = sum(1 for r in sel if r[arm + "_compiles"] == "yes")
            line[arm + "_compiles"] = n
            line[arm + "_compiles_pct"] = pct(n, len(sel))
        for arm in ("obfuscated", "deobf_gpt4o", "deobf_deepseek"):
            comp = [r for r in sel if r[arm + "_comparable"] == "yes"]
            exact = sum(1 for r in comp if r[arm + "_exact_match"] == "yes")
            sims = [r[arm + "_similarity"] for r in comp if r[arm + "_similarity"] != ""]
            line[arm + "_comparable"] = len(comp)
            line[arm + "_exact_match"] = exact
            line[arm + "_exact_pct"] = pct(exact, len(comp))
            line[arm + "_mean_similarity"] = round(sum(sims) / len(sims), 4) if sims else 0.0
        summary.append(line)

    # failure reasons for the two LLM arms
    reasons = defaultdict(lambda: defaultdict(int))
    for r in rows:
        for arm in ("obfuscated", "deobf_gpt4o", "deobf_deepseek"):
            if r[arm + "_compiles"] != "yes":
                reasons[arm][r[arm + "_status"]] += 1

    os.makedirs(OUT_DIR, exist_ok=True)
    sum_path = os.path.join(OUT_DIR, "deobfuscation_compile_summary.csv")
    with open(sum_path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(summary[0].keys()))
        w.writeheader()
        w.writerows(summary)

    try:
        import pandas as pd
        xlsx = os.path.join(OUT_DIR, "deobfuscation_bytecode_comparison.xlsx")
        with pd.ExcelWriter(xlsx, engine="openpyxl") as xw:
            pd.DataFrame(summary).to_excel(xw, sheet_name="summary", index=False)
            per = pd.DataFrame(rows)
            per.drop(columns=[c for c in per.columns if c.endswith("_pinned_ok")]) \
               .to_excel(xw, sheet_name="per_contract", index=False)
            rd = [{"arm": a, "reason": k, "count": v}
                  for a, d in reasons.items() for k, v in sorted(d.items(), key=lambda x: -x[1])]
            pd.DataFrame(rd).to_excel(xw, sheet_name="failure_reasons", index=False)
        print("Wrote", xlsx)
    except ImportError:
        print("pandas not available - CSV only")
    print("Wrote", sum_path)

    # ---- console report ----
    allr = summary[-1]
    print("\n=== Compilability (own pragma), all %d contracts ===" % allr["contracts"])
    for arm in ARMS:
        print("  %-16s %4d  (%5.1f%%)" % (arm, allr[arm + "_compiles"], allr[arm + "_compiles_pct"]))
    print("\n=== Bytecode vs original (same pinned solc, both compiled) ===")
    for arm in ("obfuscated", "deobf_gpt4o", "deobf_deepseek"):
        print("  %-16s comparable %3d   exact %3d (%5.1f%%)   mean similarity %.3f"
              % (arm, allr[arm + "_comparable"], allr[arm + "_exact_match"],
                 allr[arm + "_exact_pct"], allr[arm + "_mean_similarity"]))
    print("\n=== Why files fail to compile ===")
    for arm in ("obfuscated", "deobf_gpt4o", "deobf_deepseek"):
        top = sorted(reasons[arm].items(), key=lambda x: -x[1])[:6]
        print("  %s: %s" % (arm, ", ".join("%s=%d" % t for t in top) or "none"))


if __name__ == "__main__":
    main()
