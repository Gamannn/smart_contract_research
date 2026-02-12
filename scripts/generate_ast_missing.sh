#!/bin/bash

# Generate AST files for the 35 missing contracts
# Usage: ./generate_ast_missing.sh

echo "=== Generating AST files for 35 missing contracts ==="

# List of missing contracts
missing="005 014 025 049 069 085 102 106 110 112 114 115 125 130 135 139 140 141 142 146 148 149 156 164 167 168 169 172 174 176 185 187 188 191 196"

# Version mapping based on pragma
get_version() {
    local file="$1"
    local pragma=$(grep -oE "pragma solidity[ ^0-9.]+" "$file" 2>/dev/null | sed 's/pragma solidity //; s/\^//')
    case "$pragma" in
        "0.4.11") echo "0.4.11" ;;
        "0.4.14") echo "0.4.14" ;;
        "0.4.15") echo "0.4.15" ;;
        "0.4.16") echo "0.4.16" ;;
        "0.4.18") echo "0.4.18" ;;
        "0.4.19") echo "0.4.19" ;;
        "0.4.20") echo "0.4.20" ;;
        "0.4.21") echo "0.4.21" ;;
        "0.4.23") echo "0.4.23" ;;
        "0.4.24") echo "0.4.24" ;;
        "0.4.25") echo "0.4.25" ;;
        "0.4.26") echo "0.4.26" ;;
        "0.5.0") echo "0.5.0" ;;
        "0.5.1") echo "0.5.1" ;;
        "0.5.10") echo "0.5.10" ;;
        "0.5.11") echo "0.5.11" ;;
        "0.5.16") echo "0.5.16" ;;
        *) echo "0.4.18" ;;  # default
    esac
}

success=0
failed=0

for num in $missing; do
    sol_file="Smart-contract-obfuscation/original_contracts/batch_01/batch01_contract_${num}.sol"
    ast_file="${sol_file}_json.ast"
    
    if [ ! -f "$sol_file" ]; then
        echo "[SKIP] batch01_contract_${num}.sol - File not found"
        continue
    fi
    
    if [ -f "$ast_file" ]; then
        echo "[DONE] batch01_contract_${num}.sol - AST already exists"
        ((success++))
        continue
    fi
    
    version=$(get_version "$sol_file")
    echo "[*] batch01_contract_${num}.sol (solc $version)..."
    
    solc-select use "$version" >/dev/null 2>&1
    
    if solc --ast-json --overwrite "$sol_file" -o "$(dirname "$sol_file")" 2>/dev/null; then
        echo "  ✓ Generated AST"
        ((success++))
    else
        echo "  ✗ Failed"
        ((failed++))
    fi
done

echo ""
echo "=== Summary ==="
echo "Generated: $success"
echo "Failed: $failed"
