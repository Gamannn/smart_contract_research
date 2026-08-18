# TODO

## Done
- [x] Batches 01–05 collected (1000 contracts)
- [x] AST generation (822/1000)
- [x] BiAn obfuscation (756/1000) — see PROGRESS.md
- [x] Hardhat bytecode extraction + comparison, all 5 batches
- [x] Vulnerability scans (Mythril, Slither, Oyente, Osiris) on original + obfuscated, all 5 batches
- [x] LLM deobfuscation, GPT-4o + DeepSeek, 756/756 each
- [x] Excel reports per batch + combined
- [x] 18 analysis figures

## Open

1. [ ] Re-run the 31 unusable deobfuscation outputs (30 truncated, 1 refusal).
       List: `deobfuscation/KNOWN_ISSUES.md`. Raise the output-token limit before rerunning;
       delete the bad file first, since the runners skip contracts that already have output.

2. [ ] Feed the deobfuscated contracts through the pipeline. Hardhat and SmartBugs currently
       cover original + obfuscated only. The open research question — does deobfuscation
       restore tool detection rates? — needs a third arm:
       - [ ] Compile deobfuscated outputs, record success rate vs. obfuscated
       - [ ] Run the four scanners over them
       - [ ] Extend the tool-efficiency reports and plots with the deobfuscated column

3. [ ] Recover the contracts lost during obfuscation, if worth it:
       - 178 never produced an AST (batch 03 alone accounts for 116 — pragma mismatches)
       - 66 produced an AST but failed inside BiAn (21 in batch 01, 43 in batch 02)

4. [ ] Consolidate `scripts/` — 9 near-duplicate `generate_ast_*.sh` and 10 `obfuscate_*.sh`
       variants. The batch 04/05 versions with version detection are the ones that worked.
