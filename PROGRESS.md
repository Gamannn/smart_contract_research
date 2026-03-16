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

### Commit 5: Obfuscation Results (Batch 01)
```bash
git add Smart-contract-obfuscation/obfuscated_contracts/
git commit -m "results: Add 166 successfully obfuscated contracts

Obfuscation transformations applied:
- Variable name replacement with hash-like identifiers (Ox...)
- Comment deletion
- Code formatting disruption
- Static data dynamic generation
- Scalar to vector conversion

Success rate: 166/183 (90.7%) for contracts with AST files
17 contracts failed during obfuscation (unsupported features)
17 contracts missing AST files (cannot be processed)"
```

### Commit 6: Batch 02 Obfuscation Results
```bash
git add Smart-contract-obfuscation/obfuscated_contracts/batch_02/
git commit -m "results: Add 174 successfully obfuscated contracts for batch_02

Obfuscation transformations applied:
- Variable name replacement with hash-like identifiers (Ox...)
- Comment deletion
- Code formatting disruption
- Static data dynamic generation
- Scalar to vector conversion

Success rate: 174/174 (100%) for contracts with AST files
26 contracts missing AST files (cannot be processed)"
```

---

## Files Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `BiAn/src/dataflowObfuscation.py` | Modified | Fixed color variable bugs |
| `BiAn/src/layoutConfuse.py` | Modified | Fixed color variable bugs |
| `scripts/generate_ast.sh` | Created | Generate AST for single contract |
| `scripts/generate_ast_parallel.sh` | Created | Generate AST files in parallel |
| `scripts/generate_ast_missing.sh` | Created | Generate AST for missing contracts |
| `scripts/generate_ast_remaining.sh` | Created | Generate remaining AST files |
| `scripts/generate_ast_and_obfuscate_missing.sh` | Created | Generate AST and obfuscate missing contracts |
| `scripts/obfuscate_one.sh` | Created | Obfuscate single contract |
| `scripts/obfuscate_batch.sh` | Created | Sequential batch obfuscation |
| `scripts/obfuscate_batch_robust.sh` | Created | Robust batch obfuscation with timeouts |
| `scripts/obfuscate_missing_and_failed.sh` | Created | Obfuscate contracts that previously failed |
| `Smart-contract-obfuscation/original_contracts/batch_01/*.sol_json.ast` | Created/Updated | 188 AST files |
| `Smart-contract-obfuscation/original_contracts/batch_02/*.sol_json.ast` | Created | 174 AST files |
| `Smart-contract-obfuscation/obfuscated_contracts/bian/*.sol` | Created/Updated | 168 obfuscated contracts (Batch 01) |
| `Smart-contract-obfuscation/obfuscated_contracts/batch_02/*.json` | Created | 174 obfuscated AST outputs |

---

## Obfuscation Statistics (Batch 01)

```
Total contracts in batch_01: 200
Contracts with AST files: 188 (94%)
Successfully obfuscated: 168 (84%)
Failed (has AST but failed obfuscation): 20
Missing AST files: 12 (cannot be processed without AST)
Success rate: 89.4% (168/188 with AST)
```

### Obfuscation Success Breakdown:
- ✅ Successfully Obfuscated: 168 contracts
- ❌ Failed Obfuscation (have AST): 20 contracts
- ❌ Missing AST Files: 12 contracts

### Successfully Obfuscated Contracts
168 contracts successfully obfuscated using BiAn v0.9.

**Failed contracts (have AST but failed during obfuscation):**
```
batch01_contract_014, 025, 049, 085, 102, 106, 112, 114, 115, 135,
139, 140, 141, 142, 148, 149, 156, 164, 168, 172, 174, 176, 188, 198
```

**Missing AST files (12 contracts - cannot be processed without AST):**
```
batch01_contract_049, 069, 110, 125, 130, 146, 167, 169, 185, 187, 191, 196
```

---

## Obfuscation Statistics (Batch 02)

```
Total contracts in batch_02: 200
Contracts with AST files: 174 (87%)
Successfully obfuscated: 174 (87%)
Failed (has AST but failed obfuscation): 0
Missing AST files: 26 (cannot be processed without AST)
Success rate: 100% (174/174 with AST)
```

### Obfuscation Success Breakdown (Batch 02)

* ✅ Successfully Obfuscated: 174 contracts
* ❌ Failed Obfuscation (have AST): 0 contracts
* ❌ Missing AST Files: 26 contracts

### Successfully Obfuscated Contracts (Batch 02)

174 contracts successfully obfuscated using BiAn v0.9.

All contracts with valid AST files were processed without runtime errors.

### Missing AST Files (26 contracts – cannot be processed without AST)

```
contract_012, contract_024, contract_025, contract_033,
contract_045, contract_046, contract_052, contract_064,
contract_080, contract_083, contract_084, contract_088,
contract_090, contract_091, contract_094, contract_097,
contract_118, contract_126, contract_134, contract_168,
contract_173, contract_176, contract_188, contract_197,
contract_199, contract_200
```

---

## Known Limitations & Root Causes (Batch 02)

### 1. Solidity Version Compatibility Issues

BiAn v0.9 primarily supports Solidity 0.4.x AST structures.
Several contracts in batch_02 require different compiler versions, causing AST generation failures.

Observed issues include:

* Constructor syntax differences (`constructor()` vs contract-name constructor)
* Deprecated visibility patterns
* Strict parsing rules in newer Solidity versions
* Incompatible pragma directives

Example compiler error:

```
Error: Expected identifier, got 'LParen'
constructor() public {
```

### 2. Compiler-Level Failures During AST Generation

All 26 failed contracts were due to compilation errors prior to obfuscation.

No transformation-level failures were observed in batch_02.

---

## Comparative Observation (Batch 01 vs Batch 02)

Unlike batch_01 (which had transformation failures), batch_02 showed:

* 100% obfuscation success for valid AST inputs
* All failures occurred at AST generation stage
* No invalid JSON outputs
* No partially corrupted obfuscation artifacts

This indicates improved pipeline stability when AST compatibility is ensured.

---

## Known Limitations & Root Causes

### 1. **Solidity Version Compatibility Issues**

**BiAn v0.9 was designed for Solidity 0.4.x**, but many contracts use newer versions (0.5.x - 0.8.x) causing AST generation failures:

| Issue | Description | Example Error |
|-------|-------------|---------------|
| `pure` keyword | Introduced in Solidity 0.5.0 | `Expected token LBrace got reserved keyword 'Pure'` |
| `view` keyword changes | New visibility modifiers | `Expected identifier, got 'LParen'` |
| `constructor` syntax | Replaced function-name syntax in 0.5.0+ | `constructor() public` vs `ContractName()` |
| ABI encoding | New encoding format | Multiple function signature changes |
| SafeMath libraries | `internal pure` not in 0.4.x | Parser cannot recognize syntax |

### 2. **Unsupported Language Features**

The following Solidity features cause BiAn transformations to fail:

- **Function modifiers**: `pure`, `view`, `payable` combinations
- **Constructor changes**: New `constructor` keyword (0.5.0+)
- **Array syntax**: `string[]` vs older array declarations
- **Gas/stipend changes**: `msg.gas` removal in 0.5.0
- **Event changes**: `anonymous` events with indexed parameters
- **Error handling**: `revert()`, `require()` with string arguments

### 3. **Compiler Errors During AST Generation**

```
batch01_contract_049.sol:13:49: Error: Expected token LBrace got reserved keyword 'Pure'
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                                                ^

batch01_contract_069.sol:390:1: Error: Source file requires different compiler version
pragma solidity 0.5.12;
^---------------------^
```

### 4. **Transformation Pipeline Errors**

Even with valid AST, the obfuscation pipeline fails with:
```
Convert integer literals to arithmetic expressions...Exception occurs
Split boolean variables...Exception occurs
```

This creates intermediate contracts with invalid Solidity syntax.

### 5. **Post-Transformation Compilation Failures**

Generated obfuscated contracts may have:
- Undeclared identifiers
- Invalid function signatures
- Missing type declarations
- Corrupted import statements

---

## Solutions Needed

1. **Update BiAn to support modern Solidity versions** (0.5.x - 0.8.x)
2. **Pre-process contracts** to downgrade 0.5.x+ syntax to 0.4.x compatible code
3. **Fork BiAn tool** to add version-specific transformation rules
4. **Skip incompatible contracts** or mark them for manual processing
5. **Add error recovery** in transformation pipeline to handle partial failures

---

## Commands Used

```bash
# Generate AST for a contract
solc-select use 0.4.18
solc --ast-json --overwrite contract.sol -o .

# Run obfuscation
cd BiAn/src
python3 main.py contract.sol contract.sol_json.ast

# Run batch obfuscation
cd BiAn
./obfuscate_batch.sh

# Obfuscate previously failed contracts
cd /Users/gaman/Desktop/smart_contract_research
bash scripts/obfuscate_missing_and_failed.sh
```

---

## Next Steps

### Batch 01 Progress:
1. ✅ Generate AST files for contracts using compatible Solidity versions (188/200 complete)
2. ✅ Obfuscate contracts with valid AST (168/188 complete)
3. ⏳ Investigate 20 failed contracts (may require BiAn tool updates)
4. ⏳ Generate AST for 12 remaining contracts (version compatibility issues)
5. ⏳ Verify obfuscated contracts compile correctly
6. ⏳ Analyze obfuscation effectiveness metrics
7. ⏳ Compare obfuscated contracts with originals

### Batch 02 Progress:
1. ✅ Generate AST files for batch_02 contracts (174/200 complete)
2. ✅ Obfuscate batch_02 contracts with valid AST (174/174 complete - 100% success rate)
3. ⏳ Generate AST for 26 remaining contracts (version compatibility issues)
4. ⏳ Implement version-aware AST generation
5. ⏳ Install additional solc compiler versions
6. ⏳ Recover remaining 26 contracts
7. ⏳ Validate compilation of obfuscated outputs
8. ⏳ Perform structural comparison analysis

