# Notation: analysis artefacts vs. the paper

The spreadsheets in this directory were produced before the manuscript was
revised, and use a different label for one transform class. **No spreadsheet has
been edited.** This file records the correspondence.

## The mapping

| Artefacts call it | Paper calls it | What it actually does |
|---|---|---|
| `T1` | `T_1^id`  | Identifier renaming to `Ox`-prefixed hex hashes |
| `T2` | `T_2`     | State-variable struct packing (`scalar2Vector`), literal-to-expression, boolean splitting, static-data generation |
| `T3` | `T_1^ws`  | Whitespace / layout compression: comment removal, flatten multi-line to one line |
| `T4` | — | Opaque predicates / dead code. **Never observed.** |
| `T5` | — | Content truncation (obfuscator emitted a subset of the original functions) |

In the paper, `T_1 = T_1^id ∪ T_1^ws` (both are layout transforms in Collberg's
taxonomy) and `T = T_1 ∘ T_2`.

## Why the paper renamed T3

`T1`, `T2`, `T3` read as Collberg's first three classes — layout, data flow,
**control flow**. BiAn implements no control-flow transform, so the third label
was misleading. Two records in this directory establish that:

- `contract_analysis_combined_summary.xlsx` → `3_Technique_Impact` row 6
  defines `T3` as *"Whitespace / Layout Compression — flattens multi-line to 1
  line"*. It is a layout transform.
- The same sheet, row 7, defines `T4` as opaque predicates and records
  *"NOT OBSERVED in any analyzed contract (CC delta = 0 in all 19)"*.

Corroborated outside this directory by `BiAn/README.md` line 7 ("Control flow
obfuscation. This aspect will be developed by the project collaborator
ZhangMeng.") and by `BiAn/src/Configuration.json`, which has no control-flow
toggle.

## Where the labels appear

`T1`/`T2`/`T3` occur in structured columns and in free-text commentary in:

    Analysis/Combined/contract_analysis_combined_summary.xlsx
        3_Technique_Impact, 2_Survivor_Contracts, 6_Conclusions_Formulas
    Analysis/Combined/bytecode_comparison_combined_all_batches.xlsx
        2_Main_Comparison ("Obf Level"), 4_Divergence_Patterns ("Obf Technique"),
        5_Final_Synthesis
    Analysis/batch_0N/contract_analysis_report_batch0N.xlsx
    Analysis/batch_0N/bytecode_comparison_report_batch0N.xlsx

They are deliberately left as-is. These files are the dated record of the
analysis as performed; rewriting them to match later manuscript wording would
remove the audit trail and risk corrupting the only clean copy of the data.

The same correspondence is stated in the paper, in the footnote to the
transform-regime table.
