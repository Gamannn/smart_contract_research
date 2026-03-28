# Smart Contract Obfuscation TODO - Batch 05 with Version Checks

## Current Status
- Batch 04: Complete (164/200 success)
- Batch 05: Pending (200 contracts ready)

## Detailed Steps for Batch 05 (Enhanced with 0.4.x-0.8.x checks)
1. [ ] Verify/install solc-select: `brew install solc-select` if needed; `solc-select install 0.4.18 0.4.26 0.5.17 0.6.12 0.7.6 0.8.19`
2. [ ] Generate ASTs with version detection: `bash scripts/generate_ast_batch05.sh`
3. [ ] Run obfuscation with post-obf multi-version checks: `bash scripts/obfuscate_batch05.sh`
4. [ ] Verify results: 
   - Count: `ls Smart-contract-obfuscation/obfuscated_contracts/bian/batch_05/*.sol | wc -l`
   - Sample logs: `tail -n 5 logs/batch05_*.log | head -10`
   - AST success rate: `ls Smart-contract-obfuscation/original_contracts/batch_05/*_json.ast | wc -l`
5. [ ] Update PROGRESS.md with metrics (e.g., Success: XX/200, Version compat %)
6. [ ] Mark batch_05 complete

## Next Action
Proceed step-by-step, checking each ✓ before next.

