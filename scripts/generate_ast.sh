#!/bin/bash

# Generate JSON AST files for all Solidity contracts
# This is required for the BiAn obfuscation tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_01"

echo "[+] Generating JSON AST files for contracts..."
echo "[+] Input directory: $INPUT_DIR"
echo ""

count=0
missing=0

for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    # Skip if AST file already exists
    if [ -f "$ast_file" ]; then
        continue
    fi
    
    # Extract pragma version
    version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$sol_file" | head -1)
    
    if [ -n "$version" ]; then
        # Try to install and use the version
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
    fi
    
    echo "Generating AST for: $filename (solc: $(solc --version | head -1))"
    
    # Generate AST using solc
    cd "$INPUT_DIR"
    solc --ast-json --pretty-json --overwrite "$filename" -o . >/dev/null 2>&1
    
    if [ -f "$ast_file" ]; then
        echo "  [✓] Generated: $ast_file"
        ((count++))
    else
        echo "  [✗] Failed to generate AST"
        ((missing++))
    fi
done

echo ""
echo "[+] AST generation complete!"
echo "[+] Generated: $count"
echo "[+] Failed/Missing: $missing"
echo "[+] Total contracts with AST: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l)"

