# BiAn Smart Contract Obfuscation Research - Progress Report

## Summary
This project applies the BiAn v0.9 obfuscation tool to smart contracts from the `Smart-contract-obfuscation` dataset.

---

## Git Commit History

### Commit 1: Initial Setup & Bug Fixes
```bash
git add BiAn/src/dataflowObfuscation.py BiAn/src/layoutConfuse.py
git commit -m "fix: Add missing color variable definitions for macOS compatibility

- Added backGreenFrontWhite, yellow, white variables in else block
- Fixed NameError when running on macOS systems
- BiAn tool now runs without color-related errors"
```

### Commit 2: Solidity Compiler Installation
```bash
git commit -m "build: Install solc 0.4.18 for AST generation

- Install solidity via Homebrew
- Configure solc-select for legacy compiler versions
- Required for parsing Solidity 0.4.x contracts"
```

### Commit 3: AST Generation Script
```bash
git add BiAn/generate_ast.sh
git commit -m "feat: Add AST generation script for batch contracts

- Generate .sol_json.ast files for each contract
- Use solc 0.4.18 for compilation
- Pre-generate ASTs before obfuscation"
```

### Commit 4: Batch Obfuscation Script
```bash
git add BiAn/obfuscate_batch.sh
git commit -m "feat: Add batch obfuscation automation script

- Process all 200 contracts in batch_01 automatically
- Generate AST files on-the-fly if missing
- Save obfuscated outputs to obfuscated_contracts/bian/
- Track success/failure statistics"
```

### Commit 5: Obfuscation Results
```bash
git add Smart-contract-obfuscation/obfuscated_contracts/
git commit -m "results: Add 26 successfully obfuscated contracts

Obfuscation transformations applied:
- Variable name replacement with hash-like identifiers (Ox...)
- Comment deletion
- Code formatting disruption
- Static data dynamic generation
- Scalar to vector conversion

Success rate: 26/200 (13%)
Failed: 174 contracts due to tool limitations"
```

---

## Files Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `BiAn/src/dataflowObfuscation.py` | Modified | Fixed color variable bugs |
| `BiAn/src/layoutConfuse.py` | Modified | Fixed color variable bugs |
| `BiAn/generate_ast.sh` | Created | Generate AST for single contract |
| `BiAn/obfuscate_batch.sh` | Created | Batch obfuscation script |
| `Smart-contract-obfuscation/original_contracts/batch_01/*.sol_json.ast` | Created | 200 AST files |
| `Smart-contract-obfuscation/obfuscated_contracts/bian/*.sol` | Created | 26 obfuscated contracts |

---

## Obfuscation Statistics

```
Total contracts in batch_01: 200
Successfully obfuscated: 26
Failed: 174
Success rate: 13%
```

### Successfully Obfuscated Contracts
```
batch01_contract_001, 012, 013, 035, 038, 048, 051, 053, 064, 070,
086, 091, 096, 097, 098, 134, 137, 143, 151, 155, 178, 189,
192, 193, 198, 199
```

---

## Known Limitations

1. **Intermediate Compilation Errors**: BiAn generates intermediate code that fails to compile for many contracts
2. **String Encoding Issues**: Contracts with special strings (e.g., "Ethereum Signed Message") cause parsing errors
3. **Legacy Solidity Support**: Tool designed for Solidity 0.4.x but has compatibility issues

---

## Commands Used

```bash
# Generate AST for a contract
solc-select use 0.4.18
solc --ast-json --pretty-json --overwrite contract.sol -o .

# Run obfuscation
cd BiAn/src
python3 main.py contract.sol contract.sol_json.ast

# Run batch obfuscation
cd BiAn
./obfuscate_batch.sh
```

---

## Next Steps

1. Analyze why 174 contracts failed
2. Fix BiAn tool compatibility issues
3. Increase success rate beyond 13%
4. Compare obfuscated contracts with originals

