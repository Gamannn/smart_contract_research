#!/bin/bash

# Fixed Improved Parallel AST generation - correct arg passing

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_03"
cd "$(dirname "$0")/.."

echo "[+] Fixed Improved Parallel AST generation for batch_03"
echo "[+] Input: $INPUT_DIR"

generate_ast() {
    local sol_file="$1"
    local filename=$(basename "$sol_file")
    local ast_file="${sol_file%.sol}.sol_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        return 0
    fi
    
    echo "  Processing $filename"
    
    # Extract version
    local version=$(grep -i '^pragma solidity' "$sol_file" | sed -E 's/.*([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/' | head -1)
    if [ -z "$version" ]; then
        version=$(grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' "$sol_file" | head -1)
    fi
    
    # Use version or fallback
    if [ -n "$version" ]; then
        echo "    Detected version $version"
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
    fi
    echo "    Using solc $(solc-select version)"
    
    cd "$INPUT_DIR" || return 1
    
    if solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null; then
        echo "  [OK] $filename"
    elif solc-select use 0.4.18 && solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null; then
        echo "  [OK 0.4.18] $filename"
    else
        echo "  [FAIL] $filename - check compilation errors"
        return 1
    fi
}
export -f generate_ast

echo "[+] Finding missing..."
missing_files=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    ast_file="${sol_file%.sol}.sol_json.ast"
    if [ ! -f "$ast_file" ]; then
        missing_files+=("$sol_file")
    fi
done

echo "[+] ${#missing_files[@]} missing AST"

# Fixed xargs for single arg
printf '%s\n' "${missing_files[@]}" | xargs -P 8 -I {} bash -c 'generate_ast "$1"' _ {}

echo ""
echo "[+] Complete! Total AST: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l || echo 0)"

