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
| 01    | 168           | 168        | 168          |
| 02    | 149           | 149        | 149          |
| 03    | 84            | 84         | 84           |
| 04    | 164           | 164        | 164          |
| 05    | 191           | 191        | 191          |
| **Total** | **756**   | **756**    | **756**      |

100% coverage for both models. Run logs: `deobfuscation/logs/`.
Output caveats are tracked in `deobfuscation/KNOWN_ISSUES.md`.

## Downstream analysis

- Bytecode extraction/comparison: `hardhat/RESULTS/batchXX/` — all 5 batches
- Vulnerability scans (Mythril, Slither, Oyente, Osiris): `smartbugs/RESULTS/batch_XX/{original,obfuscated}/` — all 5 batches, 50 CSVs
- Excel reports: `Analysis/batch_XX/` and `Analysis/Combined/`
- Figures: `Analysis/plots/` — 18 PNGs, regenerate with `generate_vuln_efficiency_plots.py`
