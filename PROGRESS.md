# Smart Contract Obfuscation Progress

All five batches are complete through obfuscation and LLM deobfuscation.

## Obfuscation (BiAn)

| Batch | Contracts | AST generated | Obfuscated | Failed at obfuscation | Skipped (no AST) |
|-------|-----------|---------------|------------|-----------------------|------------------|
| 01    | 200       | 189           | 168        | 21                    | 11               |
| 02    | 200       | 192           | 149        | 43                    | 8                |
| 03    | 200       | 84            | 84         | 0                     | 116              |
| 04    | 200       | 166           | 164        | 2                     | 34               |
| 05    | 200       | 191           | 191        | 0                     | 9                |
| **Total** | **1000** | **822**    | **756**    | **66**                | **178**          |

Output: `Smart-contract-obfuscation/obfuscated_contracts/batch_XX/`

Notes:
- Batch 03 lost 116 contracts at AST generation (pragma version mismatches).
- Batches 01–02 generated ASTs but lost 21 / 43 contracts inside BiAn itself.
- Batches 04–05 used the version-checking AST scripts and have the cleanest yield.

## Deobfuscation (LLM)

| Batch | Obfuscated in | GPT-4o out | DeepSeek out |
|-------|---------------|------------|--------------|
| 01    | 168           | 168        | 166          |
| 02    | 149           | 149        | 148          |
| 03    | 84            | 84         | 84           |
| 04    | 164           | 164        | 164          |
| 05    | 191           | 191        | 191          |
| **Total** | **756**   | **756**    | **753**      |

GPT-4o 756/756, DeepSeek 753/756. The three missing DeepSeek files
(`batch01_contract_039`, `batch01_contract_104`, `batch02_contract_094`) were
truncated responses that were deleted and never regenerated.

A further ~31 files exist but are unusable (30 truncated mid-contract, 1 GPT-4o
refusal) — see `deobfuscation/KNOWN_ISSUES.md`. Run logs: `deobfuscation/logs/`.

Both run scripts now set `max_tokens` explicitly and raise on
`finish_reason == "length"`, so a future re-run fails loudly instead of writing
a truncated file.

## Downstream analysis

- Bytecode extraction/comparison (Hardhat, original + obfuscated only): `hardhat/RESULTS/batchXX/`
- Vulnerability scans (Mythril, Slither, Oyente, Osiris): `smartbugs/RESULTS/batch_XX/{original,obfuscated}/` — all 5 batches, 50 CSVs. **No deobfuscated arm yet** (see below).
- Excel reports: `Analysis/batch_XX/` and `Analysis/Combined/`
- Figures: `Analysis/plots/` — 18 PNGs, regenerate with `generate_vuln_efficiency_plots.py`

### Four-arm compile + bytecode analysis (new)

All four arms recompiled through one consistent solc pipeline so the comparison
is apples-to-apples, rather than mixing Hardhat output with LLM output.

- `scripts/compile_and_extract_bytecode.py` — compiles original / obfuscated /
  deobf_gpt4o / deobf_deepseek. Each file is compiled twice: under its own
  pragma (**self**, measures "does it compile at all") and under the compiler
  pinned from the original contract (**pinned**, required for any bytecode
  comparison to be meaningful). Output: `hardhat/RESULTS/solc_pipeline/batch_XX/`
- `scripts/compare_bytecode_arms.py` — builds the comparison.
  Output: `Analysis/Combined/deobfuscation_bytecode_comparison.xlsx` and
  `deobfuscation_compile_summary.csv`

**Compilability (own pragma), 756 contracts:**

| Arm | Compiles | % |
|-----|----------|---|
| original | 716 | 94.7% |
| obfuscated (BiAn) | 30 | 4.0% |
| deobfuscated GPT-4o | 497 | 65.7% |
| deobfuscated DeepSeek | 531 | 70.2% |

BiAn's obfuscation destroys compilability (4.0%); both LLMs recover most of it.
This matches the existing Hardhat results, which extracted bytecode for only
19/756 obfuscated contracts.

**Deployed bytecode vs original (same pinned solc, both sides compiled):**

| Arm | Comparable | Exact match | Mean similarity |
|-----|-----------|-------------|-----------------|
| obfuscated | 29 | 6 (20.7%) | 0.664 |
| deobf GPT-4o | 473 | 16 (3.4%) | 0.406 |
| deobf DeepSeek | 504 | 21 (4.2%) | 0.463 |

**Caveat — exact bytecode match is the wrong metric here.** The master prompt
instructs the model to "restore meaningful function names". In a 76-contract
sample, 70 had a different set of function names from the original. Renaming a
public function changes its 4-byte selector, so identical bytecode is
unreachable by construction. The 3–4% figures measure prompt compliance, not
semantic divergence. A selector-independent metric (CFG similarity, or
differential testing against the original ABI) is needed for an equivalence
claim.
