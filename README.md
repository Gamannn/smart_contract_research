# Smart Contract Obfuscation Research

A research project investigating the effectiveness, limitations, and security implications of source-code obfuscation applied to Solidity smart contracts. The study examines whether obfuscation truly provides security benefits, whether obfuscated contracts remain compilable, whether vulnerability detection tools can still identify issues in obfuscated code, and whether LLMs can reverse the obfuscation.

---

## Research Questions

1. **Is obfuscation actually useful for smart contracts?** Does it meaningfully hide logic or vulnerabilities?
2. **Does obfuscation break compilation?** Can obfuscated contracts still be compiled via Hardhat?
3. **Do vulnerability detection tools still work?** Can Mythril, Slither, Oyente, and Osiris detect issues in obfuscated code?
4. **Can LLMs deobfuscate contracts?** How well do GPT-4o and DeepSeek reverse the obfuscation?
5. **What are the faults of obfuscation?** Bytecode-level analysis and source code comparison to understand what actually changes.

---

## Project Structure

```
smart_contract_research/
├── Smart-contract-obfuscation/
│   ├── original_contracts/         # Raw collected Solidity contracts (batch_01–05, 1000 total)
│   └── obfuscated_contracts/       # BiAn-obfuscated output (batch_01–05, 756 contracts)
├── BiAn/                           # BiAn obfuscation tool (source + config)
├── deobfuscation/
│   ├── chatgpt_outputs/            # GPT-4o deobfuscation results (batch_01–05, 756)
│   ├── deepseek_outputs/           # DeepSeek deobfuscation results (batch_01–05, 756)
│   ├── prompts/                    # Prompts used for LLM deobfuscation
│   ├── scripts/                    # Automation scripts for LLM API calls
│   └── logs/                       # Run logs
├── Analysis/
│   ├── batch_01/ … batch_05/       # Per-batch xlsx: contract analysis, bytecode, tool efficiency
│   ├── Combined/                   # Cross-batch summary xlsx
│   └── plots/                      # 18 publication figures + generator script
├── hardhat/                        # Hardhat project + RESULTS/batchXX bytecode CSVs
├── smartbugs/                      # SmartBugs runner + RESULTS/batch_XX tool CSVs
├── scripts/                        # Shell + Python scripts for AST generation & obfuscation
├── logs/                           # Obfuscation run logs per batch
├── PROGRESS.md                     # Batch-by-batch obfuscation progress log
└── TODO.md                         # Task tracker
```

---

## Pipeline Overview

### Step 1 — Data Collection

- Collected 1,000 real-world Solidity smart contracts across five batches (200 per batch).
- Contracts span Solidity versions 0.4.x through 0.8.x, sourced from on-chain verified contracts.
- Stored in `Smart-contract-obfuscation/original_contracts/batch_01` through `batch_05`.

---

### Step 2 — Obfuscation with BiAn

**Tool:** [BiAn (狴犴)](https://github.com/xf97/BiAn) — a source-code level obfuscation tool for Solidity.

**Obfuscation techniques applied:**
- **Layout obfuscation** — removes comments, disrupts formatting, replaces variable/function names
- **Data flow obfuscation** — converts integer literals to arithmetic expressions, splits boolean variables, converts scalar to vector, dynamically generates static data
- **Control flow obfuscation** — structural transformations to control paths

**Process:**
1. Generate JSON ASTs for each contract using `solc` (with version detection across 0.4.18, 0.4.26, 0.5.17, 0.6.12, 0.7.6, 0.8.19 via `solc-select`).
2. Feed each `.sol` + `.sol_json.ast` pair into BiAn's `main.py`.
3. Output stored in `Smart-contract-obfuscation/obfuscated_contracts/batch_XX/`.

**Results:**

| Batch | Contracts | AST generated | Obfuscated | Failed at obfuscation | Skipped (no AST) |
|-------|-----------|---------------|------------|-----------------------|------------------|
| 01    | 200       | 189           | 168        | 21                    | 11               |
| 02    | 200       | 192           | 149        | 43                    | 8                |
| 03    | 200       | 84            | 84         | 0                     | 116              |
| 04    | 200       | 166           | 164        | 2                     | 34               |
| 05    | 200       | 191           | 191        | 0                     | 9                |
| **Total** | **1000** | **822**    | **756**    | **66**                | **178**          |

> Batch 03 has the highest skip rate (116 contracts with no AST) due to pragma version mismatches during AST generation. Batches 01–02 generated ASTs successfully but lost 21 and 43 contracts respectively at the BiAn obfuscation step.

Scripts: `scripts/generate_ast_batch0X.sh`, `scripts/obfuscate_batch0X.sh`

---

### Step 3 — Compilation Check with Hardhat

Obfuscated contracts were compiled using **Hardhat** to verify whether BiAn's transformations preserve syntactic and semantic validity.

Key question: *Does obfuscation break the contract's ability to compile?*

Deployed bytecode is extracted per contract (`hardhat/extract_bytecode.cjs`), stripped of the
metadata tail, and compared original vs. obfuscated. Results: `hardhat/RESULTS/batchXX/`
(`main_*.csv` holds the main contract's bytecode); rolled up into
`Analysis/batch_XX/bytecode_comparison_report_batchXX.xlsx`.

---

### Step 4 — Vulnerability Detection

Vulnerability detection tools were run against both **original** and **obfuscated** versions of each contract to measure whether obfuscation affects detection rates.

**Tools used:**

| Tool | Type | Focus |
|------|------|-------|
| [Slither](https://github.com/crytic/slither) | Static analysis | General vulnerability patterns |
| [Mythril](https://github.com/ConsenSys/mythril) | Symbolic execution | Security vulnerabilities (reentrancy, overflow, etc.) |
| [Oyente](https://github.com/enzymefinance/oyente) | Symbolic execution | Classic Ethereum vulnerabilities |
| [Osiris](https://github.com/christoftorres/Osiris) | Symbolic execution | Integer overflow/underflow |

Raw tool output: `smartbugs/RESULTS/batch_XX/{original,obfuscated}/` — one CSV per tool plus a
`combined_*.csv`. Rolled up into `Analysis/batch_XX/vulnerability_tool_efficiency_report_batchXX.xlsx`
and visualised by `Analysis/plots/generate_vuln_efficiency_plots.py`.

---

### Step 5 — Deobfuscation with LLMs

Obfuscated contracts were passed to large language models with a structured prompt instructing them to deobfuscate while preserving exact functionality.

**Models used:**
- **GPT-4o (OpenAI)** — `deobfuscation/chatgpt_outputs/` (756 contracts, batch_01–05)
- **DeepSeek** — `deobfuscation/deepseek_outputs/` (756 contracts, batch_01–05)

**Prompt strategy** (`deobfuscation/prompts/master_prompt.txt`):
- Instructs the model to restore meaningful variable/function names
- Simplify arithmetic obfuscation artifacts
- Preserve exact logic, pragma version, and compilability
- Return raw Solidity only (no markdown/explanations)

Scripts: `deobfuscation/scripts/run_deobfuscate_openai.py`, `run_deobfuscate_deepseek.py`
(both resume automatically — already-present outputs are skipped — and strip any markdown
fences the model emits before writing).

**Known output caveats** (see `deobfuscation/KNOWN_ISSUES.md`): 31 of 1512 outputs (2.1%) are
unusable — 30 truncated mid-file at the model's token cap, 1 a refusal. The other 1481 are complete.

---

### Step 6 — Analysis & Comparison

Three levels of analysis were performed and results compiled into Excel reports in `Analysis/`:

**1. Source Code Analysis** (`Analysis/batch_XX/contract_analysis_report_batchXX.xlsx`)
- Structural diff between original and obfuscated/deobfuscated contracts
- Identifier renaming coverage, expression complexity increase

**2. Bytecode Comparison** (`Analysis/batch_XX/bytecode_comparison_report_batchXX.xlsx`)
- Compiled original vs. obfuscated bytecode comparison
- Determines whether obfuscation changes runtime behavior or only source appearance

**3. Vulnerability Tool Efficiency** (`Analysis/batch_XX/vulnerability_tool_efficiency_report_batchXX.xlsx`)
- Detection rate of each tool on original vs. obfuscated contracts
- Measures whether obfuscation evades or confuses analysis tools

---

## Key Findings (Summary)

- **Compilability:** Obfuscation does not always preserve compilability — version mismatches and AST-level transformations can break `solc` compilation.
- **Bytecode impact:** Layout obfuscation (renaming, formatting) has minimal impact on compiled bytecode; data/control flow obfuscation can alter it.
- **Vulnerability detection:** Tools vary in sensitivity to obfuscation — some are bytecode-based (less affected), others are source-based (more affected).
- **LLM deobfuscation:** GPT-4 and DeepSeek can partially restore obfuscated contracts, but fidelity varies with obfuscation depth. Functionality is generally preserved; naming recovery is imperfect.
- **Overall:** Obfuscation offers limited security benefit for on-chain contracts where bytecode is public — it primarily raises the barrier for source-level manual audits, not automated tools.

---

## Requirements

### Obfuscation
- Python 3.x
- `solc-select` (`brew install solc-select`)
- Solidity versions: 0.4.18, 0.4.26, 0.5.17, 0.6.12, 0.7.6, 0.8.19
- BiAn dependencies: see `BiAn/requirements.txt`

### Compilation
- Node.js, npm
- Hardhat (`npm install --save-dev hardhat`)

### Vulnerability Analysis
- Slither (`pip install slither-analyzer`)
- Mythril (`pip install mythril`)
- Oyente / Osiris (Docker recommended)

### Deobfuscation
- OpenAI Python SDK (`pip install openai`)
- DeepSeek API access

---

## Usage

```bash
# 1. Generate ASTs for a batch
bash scripts/generate_ast_batch04.sh

# 2. Obfuscate using BiAn
bash scripts/obfuscate_batch04.sh

# 3. Deobfuscate with GPT-4o (--batch is required; reruns skip existing outputs)
python3 deobfuscation/scripts/run_deobfuscate_openai.py --batch 4

# 4. Deobfuscate with DeepSeek
python3 deobfuscation/scripts/run_deobfuscate_deepseek.py --batch 4

# 5. Regenerate the analysis figures from the xlsx reports
python3 Analysis/plots/generate_vuln_efficiency_plots.py
```

API keys are read from the environment (`OPENAI_API_KEY`, `DEEPSEEK_API_KEY`); `deobfuscation/.env`
is gitignored and never committed.

---

## Batch Progress

See [PROGRESS.md](PROGRESS.md) for detailed per-batch obfuscation metrics and notes.

---

## References

- [BiAn: Smart Contract Obfuscation Tool](https://github.com/xf97/BiAn)
- [Slither](https://github.com/crytic/slither)
- [Mythril](https://github.com/ConsenSys/mythril)
- [Oyente](https://github.com/enzymefinance/oyente)
- [Osiris](https://github.com/christoftorres/Osiris)
- [Hardhat](https://hardhat.org/)
