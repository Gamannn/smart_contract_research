#!/bin/bash

# Generate AST files for remaining contracts with aggressive patching
# Usage: ./generate_ast_remaining.sh

echo "=== Generating AST for remaining 17 contracts ==="

# Function to generate AST with fallback strategies
generate_ast() {
    local num="$1"
    local sol_file="Smart-contract-obfuscation/original_contracts/batch_01/batch01_contract_${num}.sol"
    local ast_file="${sol_file}_json.ast"
    local backup="/tmp/batch01_contract_${num}.sol.backup"
    
    if [ ! -f "$sol_file" ]; then
        echo "[SKIP] ${num} - File not found"
        return 1
    fi
    
    if [ -f "$ast_file" ]; then
        echo "[DONE] ${num} - Already exists"
        return 0
    fi
    
    # Backup original
    cp "$sol_file" "$backup"
    
    # Try strategy 1: Add pragma if missing
    if ! grep -q "pragma solidity" "$sol_file"; then
        echo "  → Adding pragma 0.4.18..."
        sed -i '' '1a pragma solidity ^0.4.18;' "$sol_file"
    fi
    
    # Try strategy 2: Patch problematic patterns
    # Fix constructor keyword (0.4.x doesn't have it)
    sed -i '' 's/constructor(/function constructor(/g' "$sol_file"
    
    # Fix fallback function (0.5.0 requires external)
    sed -i '' 's/function() public payable/function() external payable/g' "$sol_file"
    
    # Fix address comparisons (0.5.0 changed this)
    sed -i '' 's/!= 0x0/!= address(0)/g' "$sol_file"
    
    # Fix transfer calls on address type
    sed -i '' 's/\.transfer(/\.transfer(/g' "$sol_file"
    
    # Try with 0.4.18
    solc-select use 0.4.18 >/dev/null 2>&1
    if solc --ast-json --overwrite "$sol_file" -o "$(dirname "$sol_file")" 2>/dev/null; then
        mv "$backup" "$sol_file" 2>/dev/null
        echo "  ✓ Generated with 0.4.18"
        return 0
    fi
    
    # Restore and try with 0.5.0
    cp "$backup" "$sol_file"
    sed -i '' 's/pragma solidity \^0\.[0-9.]+/pragma solidity 0.5.0;/g' "$sol_file"
    solc-select use 0.5.0 >/dev/null 2>&1
    
    if solc --ast-json --overwrite "$sol_file" -o "$(dirname "$sol_file")" 2>/dev/null; then
        mv "$backup" "$sol_file" 2>/dev/null
        echo "  ✓ Generated with 0.5.0 (patched pragma)"
        return 0
    fi
    
    # Restore and try with 0.6.0
    cp "$backup" "$sol_file"
    sed -i '' 's/pragma solidity \^0\.[0-9.]+/pragma solidity 0.6.0;/g' "$sol_file"
    solc-select use 0.6.0 >/dev/null 2>&1
    
    if solc --ast-json --overwrite "$sol_file" -o "$(dirname "$sol_file")" 2>/dev/null; then
        mv "$backup" "$sol_file" 2>/dev/null
        echo "  ✓ Generated with 0.6.0 (patched pragma)"
        return 0
    fi
    
    # Restore original
    mv "$backup" "$sol_file"
    echo "  ✗ Failed (all strategies)"
    return 1
}

# Contracts to process
remaining="049 069 110 114 125 130 146 156 167 169 174 176 185 187 188 191 196"

success=0
failed=0

for num in $remaining; do
    echo "[*] batch01_contract_${num}.sol..."
    if generate_ast "$num"; then
        ((success++))
    else
        ((failed++))
    fi
done

echo ""
echo "=== Summary ==="
echo "Generated: $success"
echo "Failed: $failed"
