#!/bin/bash

# Improved Parallel AST generation for batch_03 - with version detection!

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_03"
cd "$(dirname "$0")/.."

echo "[+] Improved Parallel AST generation for batch_03 (version detection)"
echo "[+] Input: $INPUT_DIR"

generate_ast() {
    sol_file="$1"
    filename=$(basename "$sol_file")
    ast_file="${sol_file%_json.ast}_json.ast"  # Handle duplicates
    ast_file="${sol_file%.sol}_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        return 0
    fi
    
    # Extract version from pragma or fallback
    version=$(grep -i '^pragma solidity' "$sol_file" | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -1)
    if [ -z "$version" ]; then
        version=$(grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' "$sol_file" | head -1)
    fi
    
    # Use extracted version or fallback to 0.4.18 (BiAn compatible)
    if [ -n "$version" ]; then
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
        echo "    Using solc $version for $filename"
    else
        solc-select use 0.4.18
        echo "    Using fallback solc 0.4.18 for $filename"
    fi
    
    cd "$INPUT_DIR"
    
    # Try AST gen, fallback to 0.4.18 if fail
    if solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null; then
        echo "  [OK] $filename"
        return 0
    else
        solc-select use 0.4.18 >/dev/null 2>&1
        if solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null; then
            echo "  [OK fallback 0.4.18] $filename"
            return 0
        else
            echo "  [FAIL] $filename"
            return 1
        fi
    fi
}
export -f generate_ast

echo "[+] Finding contracts without AST files..."
missing_files=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    ast_file="${sol_file%.sol}.sol_json.ast"
    if [ ! -f "$ast_file" ]; then
        missing_files+=("$sol_file")
    fi
done

echo "[+] Found ${#missing_files[@]} contracts needing AST"

export INPUT_DIR

printf '%s\n' "${missing_files[@]}" | xargs -P 8 -I {} bash -c 'generate_ast \"\$@\"' _ {}

echo ""
echo "[+] Improved AST generation complete!"
echo "[+] Total AST files: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l || echo 0)"

