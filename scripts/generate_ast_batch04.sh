#!/bin/bash

# Parallel AST generation for batch_04

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_04"
cd "$(dirname "$0")/.."

echo "[+] Parallel AST generation for batch_04 starting..."
echo "[+] Input: $INPUT_DIR"

generate_ast() {
    sol_file="$1"
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        return 0
    fi
    
    solc-select use 0.8.33
    
    cd "$INPUT_DIR"
    solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null
    
    if [ -f "$ast_file" ]; then
        echo "  [OK] $filename"
        return 0
    else
        echo "  [FAIL] $filename"
        return 1
    fi
}
export -f generate_ast

export INPUT_DIR

missing_files=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    ast_file="${sol_file}_json.ast"
    if [ ! -f "$ast_file" ]; then
        missing_files+=("$sol_file")
    fi
done

echo "[+] Found ${#missing_files[@]} contracts needing AST generation"

printf '%s\n' "${missing_files[@]}" | xargs -P 8 -I {} bash -c 'generate_ast "$@"' _ {}

echo ""
echo "[+] Parallel AST generation complete!"
echo "[+] Total AST files: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l || echo 0)"

