#!/bin/bash

# Parallel AST generation - much faster!

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_01"
cd "$(dirname "$0")/.."

echo "[+] Parallel AST generation starting..."
echo "[+] Input: $INPUT_DIR"

# Export function for parallel use
generate_ast() {
    sol_file="$1"
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        return 0
    fi
    
    # Extract version and set it
    version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$sol_file" 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
    fi
    
    # Generate AST
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

# Find all missing AST files
echo "[+] Finding contracts without AST files..."
missing_files=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    ast_file="${sol_file}_json.ast"
    if [ ! -f "$ast_file" ]; then
        missing_files+=("$sol_file")
    fi
done

echo "[+] Found ${#missing_files[@]} contracts needing AST generation"

# Export variables for parallel
export INPUT_DIR

# Run parallel with 8 workers
printf '%s\n' "${missing_files[@]}" | xargs -P 8 -I {} bash -c 'generate_ast "$@"' _ {}

echo ""
echo "[+] Parallel AST generation complete!"
echo "[+] Total AST files: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l)"

