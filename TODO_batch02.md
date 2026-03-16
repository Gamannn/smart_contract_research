# Obfuscation Progress for batch_02 (200 contracts)

## Steps:

### 1. Generate AST files
- Target: Smart-contract-obfuscation/original_contracts/batch_02/batch02_contract_*.sol -> *.sol_json.ast
- Script: Custom adapted generate_ast.sh
- **Status: ✓ Complete - 149/200 AST files generated (74.5% success rate)**
- Failed: 51 contracts (compiler version issues)

### 2. Run BiAn obfuscation
- Input: contracts with valid AST (149)
- Output: Smart-contract-obfuscation/obfuscated_contracts/batch_02/batch02_contract_*_obf.sol
- Script: Custom adapted obfuscate_batch.sh (fixed paths)
- **Status: [IN PROGRESS] - Retry with absolute paths**

### 3. Verify and report
- Count success/fail rates
- Update PROGRESS.md with batch_02 results
- Commit obfuscated contracts
- **Status: Pending**

### Progress Summary
- AST Success Rate: 74.5% (149/200)
- Obfuscation: Running (expect 100% on valid AST per prior runs)
