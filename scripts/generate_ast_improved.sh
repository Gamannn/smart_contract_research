#!/bin/bash

INPUT_DIR="$1"
cd "$(dirname "$0")/.."

echo "[+] Improved AST generation for $INPUT_DIR"

generate_ast_improved() {
    sol_file="$1"
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    if [ -f "$ast_file" ]; then
        echo "  [SKIP] $filename"
        return 0
    fi
    
    # Try multiple solc versions
    versions=("0.4.26" "0.5.17" "0.6.12" "0.7.6" "0.8.0" "0.8.9" "0.8.19" "0.8.33")
    
    cd "$INPUT_DIR"
    
    for ver in "${versions[@]}"; do
        solc-select use "$ver" 2>/dev/null || continue
        solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null
        if [ -f "$ast_file" ]; then
            echo "  [OK $ver] $filename"
            return 0
        fi
    done
    
    echo "  [FAIL all] $filename"
    return 1
}
export -f generate_ast_improved

export INPUT_DIR

missing_files=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    ast_file="${sol_file}_json.ast"
    if [ ! -f "$ast_file" ]; then
        missing_files+=("$sol_file")
    fi
done

echo "[+] Found ${#missing_files[@]} contracts needing AST"

printf '%s\n' "${missing_files[@]}" | xargs -P 4 -I {} bash -c 'generate_ast_improved "$@"' _ {}

echo ""
echo "[+] Complete! AST files: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l || echo 0)"

