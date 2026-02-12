#!/bin/bash

# Generate AST files for missing contracts and obfuscate all 34 contracts
# (17 that failed + 17 that were missing AST)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_01"
BIAN_SRC="$PROJECT_ROOT/BiAn/src"

# Missing contracts that need AST generation
MISSING_CONTRACTS=(
    "069:0.5.12"
    "110:0.4.18"
    "114:>=0.5.0 <0.6.0"
    "125:0.5.16"
    "130:0.4.18"
    "146:0.4.24"
    "156:0.5.11"
    "167:0.4.18"
    "169:0.4.21"
    "174:0.5.0"
    "176:0.5.1"
    "185:0.4.15"
    "187:0.5.16"
    "188:0.5.0"
    "191:0.4.20"
    "196:0.4.23"
    "198:0.4.18"
)

# Failed contracts (have AST but failed during obfuscation)
FAILED_CONTRACTS=(
    "014"
    "025"
    "085"
    "102"
    "106"
    "112"
    "115"
    "135"
    "139"
    "140"
    "141"
    "142"
    "148"
    "149"
    "164"
    "168"
    "172"
)

echo "=============================================="
echo "Step 1: Generate AST for 17 missing contracts"
echo "=============================================="

# First, ensure all needed versions are installed
echo "[+] Ensuring required compiler versions are installed..."
solc-select install 0.5.12 >/dev/null 2>&1
solc-select install 0.4.15 >/dev/null 2>&1
solc-select install 0.4.23 >/dev/null 2>&1

ast_generated=0
ast_failed=0

for item in "${MISSING_CONTRACTS[@]}"; do
    IFS=':' read -r num version <<< "$item"
    contract="batch01_contract_${num}.sol"
    ast_file="${contract}_json.ast"
    
    if [ -f "$INPUT_DIR/$ast_file" ]; then
        echo "[✓] AST already exists: $ast_file"
        continue
    fi
    
    echo "[+] Processing: $contract (version: $version)"
    
    # Extract major.minor version for solc-select
    major_minor=$(echo "$version" | grep -oE '[0-9]+\.[0-9]+')
    
    if [ -n "$major_minor" ]; then
        solc-select use "$major_minor" >/dev/null 2>&1
    fi
    
    # Generate AST
    cd "$INPUT_DIR"
    if solc --ast-json --pretty-json --overwrite "$contract" -o . 2>/dev/null; then
        if [ -f "$INPUT_DIR/$ast_file" ]; then
            echo "  [✓] Generated AST: $ast_file"
            ((ast_generated++))
        else
            echo "  [✗] AST file not created"
            ((ast_failed++))
        fi
    else
        echo "  [✗] Failed to generate AST"
        ((ast_failed++))
    fi
done

echo ""
echo "[+] AST Generation Results:"
echo "[+] Generated: $ast_generated"
echo "[+] Failed: $ast_failed"

echo ""
echo "=============================================="
echo "Step 2: Obfuscate all 34 contracts"
echo "=============================================="

obfuscated=0
obfuscation_failed=0

# Function to obfuscate a single contract
obfuscate_contract() {
    local num=$1
    local contract="batch01_contract_${num}.sol"
    local ast_file="${contract}_json.ast"
    local output_file="${contract}_obf.sol"
    local output_dir="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian"
    
    if [ ! -f "$INPUT_DIR/$ast_file" ]; then
        echo "  [✗] Missing AST file: $ast_file"
        return 1
    fi
    
    # Get the pragma version from the contract
    local version=$(grep -oE 'pragma solidity [0-9]+\.[0-9]+\.[0-9]+' "$INPUT_DIR/$contract" | head -1 | grep -oE '[0-9]+\.[0-9]+')
    
    if [ -n "$version" ]; then
        solc-select use "$version" >/dev/null 2>&1
    fi
    
    # Run obfuscation
    cd "$BIAN_SRC"
    if python3 main.py "$INPUT_DIR/$contract" "$INPUT_DIR/$ast_file" >/dev/null 2>&1; then
        # Move output to correct location
        if [ -f "$BIAN_SRC/output.sol" ]; then
            mv "$BIAN_SRC/output.sol" "$output_dir/$output_file"
            echo "  [✓] Obfuscated: $output_file"
            return 0
        elif [ -f "$BIAN_SRC/output.sol_json.ast_obf.sol" ]; then
            mv "$BIAN_SRC/output.sol_json.ast_obf.sol" "$output_dir/$output_file"
            echo "  [✓] Obfuscated: $output_file"
            return 0
        fi
    fi
    echo "  [✗] Obfuscation failed: $contract"
    return 1
}

# Obfuscate previously missing contracts
echo "[+] Obfuscating 17 previously missing contracts..."
for item in "${MISSING_CONTRACTS[@]}"; do
    IFS=':' read -r num version <<< "$item"
    echo "[+] Processing: batch01_contract_${num}"
    if obfuscate_contract "$num"; then
        ((obfuscated++))
    else
        ((obfuscation_failed++))
    fi
done

# Obfuscate previously failed contracts
echo ""
echo "[+] Obfuscating 17 previously failed contracts..."
for num in "${FAILED_CONTRACTS[@]}"; do
    contract="batch01_contract_${num}.sol"
    if [ ! -f "$INPUT_DIR/$contract.sol" ]; then
        echo "  [✗] Contract not found: $contract"
        ((obfuscation_failed++))
        continue
    fi
    echo "[+] Processing: $contract"
    if obfuscate_contract "$num"; then
        ((obfuscated++))
    else
        ((obfuscation_failed++))
    fi
done

echo ""
echo "=============================================="
echo "FINAL RESULTS"
echo "=============================================="
echo "[+] AST Generation: $ast_generated generated, $ast_failed failed"
echo "[+] Obfuscation: $obfuscated succeeded, $obfuscation_failed failed"
echo "[+] Total contracts obfuscated: $(ls "$output_dir"/*_obf.sol 2>/dev/null | wc -l)"

