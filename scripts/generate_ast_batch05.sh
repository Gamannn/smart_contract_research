#!/bin/bash

# Parallel AST generation for batch_05

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_05"
cd "$(dirname "$0")/.."

echo "[+] Parallel AST generation for batch_05 starting..."
echo "[+] Input: $INPUT_DIR"

generate_ast() {
    sol_file="$1"
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        check_versions "$sol_file"
        return 0
    fi
    
    # Detect Solidity version (improved regex)
    version=$(grep -Eo 'pragma solidity[^
]*\K[0-9.]+\.[0-9]+\.[0-9]+' "$sol_file" 2>/dev/null | sed 's/\^//;s/\..*//' | head -1)
    if [ -z "$version" ]; then
        version="0.8.19"
        echo "  No pragma detected, fallback $version"
    else
        echo "  Detected version: $version.x"
    fi
    
    # Try gen with detected/fallback, then fallbacks if fail
    for try_version in "$version" "0.5.17" "0.6.12" "0.8.19"; do
        solc-select install "$try_version" >/dev/null 2>&1
        solc-select use "$try_version" >/dev/null 2>&1
        cd "$INPUT_DIR"
        solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null
        if [ -f "$ast_file" ] && [ -s "$ast_file" ]; then
            echo "  [OK] $filename (used $try_version)"
            break
        fi
    done
    
    cd "$INPUT_DIR"
    solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null
    
    if [ -f "$ast_file" ] && [ -s "$ast_file" ]; then
        echo "  [OK] $filename (AST gen with $version)"
        check_versions "$sol_file"
        return 0
    else
        echo "  [FAIL] $filename"
        return 1
    fi
}

check_versions() {
    local file="$1"
    local versions=("0.4.18" "0.4.26" "0.5.17" "0.6.12" "0.7.6" "0.8.19")
    local compat=0
    local total=${#versions[@]}
    
    for v in "${versions[@]}"; do
        solc-select use "$v" >/dev/null 2>&1
        if solc --ast-json "$file" >/dev/null 2>&1; then
            ((compat++))
        fi
    done
    echo "  Compat: $compat/$total versions OK"
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

