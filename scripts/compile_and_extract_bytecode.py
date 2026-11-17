#!/usr/bin/env python3
"""
Compile every arm of the experiment with one consistent solc pipeline and
extract deployed (runtime) bytecode.

Arms:
    original          Smart-contract-obfuscation/original_contracts/
    obfuscated        Smart-contract-obfuscation/obfuscated_contracts/
    deobf_gpt4o       deobfuscation/chatgpt_outputs/
    deobf_deepseek    deobfuscation/deepseek_outputs/

The existing hardhat/RESULTS CSVs only cover original + obfuscated and were
produced by Hardhat. This script re-derives all four arms the same way so the
comparison is apples-to-apples, and writes to a separate directory so nothing
already in hardhat/RESULTS/ is overwritten.

Outputs (per batch, per arm) in hardhat/RESULTS/solc_pipeline/batch_XX/:
    <arm>_bytecodes_batchXX.csv        one row per compiled contract
    <arm>_status_batchXX.csv           one row per source file (compile outcome)
"""

import csv
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOLC_DIR = os.path.expanduser("~/.solc-select/artifacts")
OUT_ROOT = os.path.join(ROOT, "hardhat", "RESULTS", "solc_pipeline")
BATCHES = ["01", "02", "03", "04", "05"]
TIMEOUT = 180

ARMS = {
    "original":       os.path.join(ROOT, "Smart-contract-obfuscation", "original_contracts"),
    "obfuscated":     os.path.join(ROOT, "Smart-contract-obfuscation", "obfuscated_contracts"),
    "deobf_gpt4o":    os.path.join(ROOT, "deobfuscation", "chatgpt_outputs"),
    "deobf_deepseek": os.path.join(ROOT, "deobfuscation", "deepseek_outputs"),
}

PRAGMA_RE = re.compile(r"pragma\s+solidity\s+([^;]+);")
CONSTRAINT_RE = re.compile(r"(\^|~|>=|<=|>|<|=)?\s*v?(\d+)\.(\d+)\.(\d+)")


def installed_versions():
    vs = []
    if not os.path.isdir(SOLC_DIR):
        return vs
    for d in os.listdir(SOLC_DIR):
        if d.startswith("solc-"):
            try:
                vs.append(tuple(int(x) for x in d[5:].split(".")))
            except ValueError:
                pass
    return sorted(vs)


VERSIONS = installed_versions()


def satisfies(ver, op, target):
    if op == "^":
        # ^0.4.x  -> >=0.4.x <0.5.0   ;  ^0.x.y for 0.x pins the minor
        if target[0] == 0:
            return ver[0] == 0 and ver[1] == target[1] and ver >= target
        return ver[0] == target[0] and ver >= target
    if op == "~":
        return ver[0] == target[0] and ver[1] == target[1] and ver >= target
    if op == ">=":
        return ver >= target
    if op == ">":
        return ver > target
    if op == "<=":
        return ver <= target
    if op == "<":
        return ver < target
    return ver == target


def pick_version(src):
    """Highest installed solc satisfying the file's first pragma."""
    m = PRAGMA_RE.search(src)
    if not m:
        return None, "no pragma"
    expr = m.group(1)
    constraints = CONSTRAINT_RE.findall(expr)
    if not constraints:
        return None, "unparsable pragma: %s" % expr.strip()
    parsed = [(op or "=", (int(a), int(b), int(c))) for op, a, b, c in constraints]
    ok = [v for v in VERSIONS if all(satisfies(v, op, t) for op, t in parsed)]
    if not ok:
        return None, "no installed solc for pragma: %s" % expr.strip()
    return ok[-1], None


def contract_id(batch, file_name):
    """batch01_contract_007_obf.sol / batch05_contract_007.sol_obf.sol -> batch05_contract_007.sol"""
    stem = file_name
    for suffix in ("_obf.sol", ".sol_obf.sol"):
        if stem.endswith(suffix):
            stem = stem[: -len(suffix)]
            break
    else:
        stem = stem[:-4] if stem.endswith(".sol") else stem
    if stem.endswith(".sol"):
        stem = stem[:-4]
    return stem + ".sol"


def run_solc(binary, path):
    """-> (returncode, stdout, first error line)"""
    try:
        proc = subprocess.run(
            [binary, "--combined-json", "bin-runtime", path],
            capture_output=True, text=True, timeout=TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return None, "", "solc timed out after %ds" % TIMEOUT
    if proc.returncode != 0:
        first = next((l.strip() for l in proc.stderr.splitlines()
                      if l.strip() and "Warning" not in l), proc.stderr[:200].strip())
        return proc.returncode, "", first[:300]
    return 0, proc.stdout, ""


def binary_for(ver):
    v = "%d.%d.%d" % ver
    b = os.path.join(SOLC_DIR, "solc-" + v, "solc-" + v)
    return b if os.path.exists(b) else None


def strip_metadata(bytecode):
    """Drop the trailing CBOR metadata blob (last 2 bytes = its length)."""
    if len(bytecode) < 4:
        return bytecode
    try:
        n = int(bytecode[-4:], 16)
    except ValueError:
        return bytecode
    cut = n * 2 + 4
    if 0 < cut < len(bytecode):
        return bytecode[:-cut]
    return bytecode


def compile_one(args):
    """Compile one source file twice:

    pinned  - the solc version chosen from the ORIGINAL contract's pragma. All
              four arms of a contract use this version, otherwise the bytecode
              comparison would be measuring compiler differences, not obfuscation.
    self    - the version this file's own pragma asks for. Measures "does this
              file compile at all", which is the metric that matters for the
              LLM output quality.

    Bytecode rows come from the pinned compile; if there is no pinned version
    they fall back to the self compile so the arm is not silently empty.
    """
    arm, batch, path, pinned = args
    name = os.path.basename(path)
    blank = {"bytecodes": [], "pinned_ver": "", "pinned_status": "", "pinned_err": "",
             "self_ver": "", "self_status": "", "self_err": ""}

    try:
        with open(path, "r", errors="replace") as f:
            src = f.read()
    except OSError as e:
        blank.update(pinned_status="unreadable", pinned_err=str(e),
                     self_status="unreadable", self_err=str(e))
        return arm, batch, name, blank

    if not src.strip():
        blank.update(pinned_status="empty", pinned_err="empty source file",
                     self_status="empty", self_err="empty source file")
        return arm, batch, name, blank

    self_ver, self_err = pick_version(src)

    def attempt(ver):
        if ver is None:
            return "no_compiler", "", []
        binary = binary_for(ver)
        if binary is None:
            return "no_compiler", "missing binary for %d.%d.%d" % ver, []
        rc, out, err = run_solc(binary, path)
        if rc is None:
            return "timeout", err, []
        if rc != 0:
            return "compile_error", err, []
        try:
            data = json.loads(out)
        except json.JSONDecodeError as e:
            return "bad_output", str(e)[:200], []
        rows = []
        for key, val in (data.get("contracts") or {}).items():
            runtime = (val.get("bin-runtime") or "").strip()
            if not runtime:
                continue          # interface / abstract contract, no deployable code
            stripped = strip_metadata(runtime)
            rows.append((key.split(":")[-1], stripped, len(stripped) // 2))
        if not rows:
            return "no_bytecode", "compiled but no deployable contract", []
        return "ok", "", rows

    results = {}
    for label, ver in (("pinned", pinned), ("self", self_ver)):
        if ver is not None and ver in results:
            continue
        results[ver] = attempt(ver)

    p_status, p_err, p_rows = results.get(pinned, ("no_compiler", "no pinned version", []))
    s_status, s_err, s_rows = results.get(self_ver, ("no_compiler", self_err or "", []))
    if self_ver is None and self_err:
        s_status, s_err = "no_compiler", self_err

    return arm, batch, name, {
        "bytecodes": p_rows if p_rows else s_rows,
        "pinned_ver": "%d.%d.%d" % pinned if pinned else "",
        "pinned_status": p_status, "pinned_err": p_err,
        "self_ver": "%d.%d.%d" % self_ver if self_ver else "",
        "self_status": s_status, "self_err": s_err,
    }


def build_version_map():
    """contract id -> solc version, decided once from the original contract."""
    vmap = {}
    base = ARMS["original"]
    for batch in BATCHES:
        d = os.path.join(base, "batch_" + batch)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if not f.endswith(".sol"):
                continue
            try:
                with open(os.path.join(d, f), "r", errors="replace") as fh:
                    ver, _ = pick_version(fh.read())
            except OSError:
                ver = None
            vmap[(batch, contract_id(batch, f))] = ver
    return vmap


def collect_jobs(vmap):
    jobs = []
    for arm, base in ARMS.items():
        for batch in BATCHES:
            d = os.path.join(base, "batch_" + batch)
            if not os.path.isdir(d):
                continue
            for f in sorted(os.listdir(d)):
                if not f.endswith(".sol"):
                    continue
                pinned = vmap.get((batch, contract_id(batch, f)))
                jobs.append((arm, batch, os.path.join(d, f), pinned))
    return jobs


def main():
    if not VERSIONS:
        sys.exit("No solc versions found under %s" % SOLC_DIR)

    only_arm = sys.argv[1] if len(sys.argv) > 1 else None
    print("Building solc version map from original contracts...", flush=True)
    vmap = build_version_map()
    pinned_ok = sum(1 for v in vmap.values() if v)
    print("  %d contract ids, %d with a resolvable compiler" % (len(vmap), pinned_ok))

    jobs = collect_jobs(vmap)
    if only_arm:
        jobs = [j for j in jobs if j[0] == only_arm]
    print("Compiling %d source files (%d solc versions available)"
          % (len(jobs), len(VERSIONS)), flush=True)

    bytecodes, statuses, done = {}, {}, 0
    with ProcessPoolExecutor(max_workers=os.cpu_count()) as pool:
        futures = [pool.submit(compile_one, j) for j in jobs]
        for fut in as_completed(futures):
            arm, batch, name, r = fut.result()
            statuses.setdefault((arm, batch), []).append(
                (name, r["pinned_ver"], r["pinned_status"], r["pinned_err"],
                 r["self_ver"], r["self_status"], r["self_err"]))
            for cname, code, nbytes in r["bytecodes"]:
                bytecodes.setdefault((arm, batch), []).append((name, cname, code, nbytes))
            done += 1
            if done % 250 == 0:
                print("  %d/%d" % (done, len(jobs)), flush=True)

    for (arm, batch), rows in sorted(statuses.items()):
        outdir = os.path.join(OUT_ROOT, "batch_" + batch)
        os.makedirs(outdir, exist_ok=True)
        with open(os.path.join(outdir, "%s_status_batch%s.csv" % (arm, batch)),
                  "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["file_name", "pinned_solc", "pinned_status", "pinned_error",
                        "self_solc", "self_status", "self_error"])
            w.writerows(sorted(rows))
        with open(os.path.join(outdir, "%s_bytecodes_batch%s.csv" % (arm, batch)),
                  "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["file_name", "contract_name", "bytecode", "size_bytes"])
            w.writerows(sorted(bytecodes.get((arm, batch), [])))

    print("\nCompile results by arm (self = own pragma, pinned = original's compiler):")
    for arm in ARMS:
        rows = [r for (a, _), rs in statuses.items() if a == arm for r in rs]
        if not rows:
            continue
        s_ok = sum(1 for r in rows if r[5] == "ok")
        p_ok = sum(1 for r in rows if r[2] == "ok")
        print("  %-16s self %4d/%4d (%5.1f%%)   pinned %4d/%4d (%5.1f%%)"
              % (arm, s_ok, len(rows), 100.0 * s_ok / len(rows),
                 p_ok, len(rows), 100.0 * p_ok / len(rows)))
        breakdown = {}
        for r in rows:
            if r[5] != "ok":
                breakdown[r[5]] = breakdown.get(r[5], 0) + 1
        for k, v in sorted(breakdown.items(), key=lambda x: -x[1]):
            print("      self %-16s %d" % (k, v))
    print("\nWrote CSVs to %s" % OUT_ROOT)


if __name__ == "__main__":
    main()
