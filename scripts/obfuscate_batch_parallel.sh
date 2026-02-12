#!/bin/bash

# Parallel batch obfuscation - much faster!

cd "$(dirname "$0")/.."

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_01"
OUTPUT_DIR="Smart-contract-obfuscation/obfuscated_contracts/bian"

mkdir -p "$OUTPUT_DIR"

echo "[+] Parallel BiAn Obfuscation"
echo "[+] Input: $INPUT_DIR"
echo "[+] Output: $OUTPUT_DIR"

# Function for parallel obfuscation
obfuscate_one() {
    sol_file="$1"
    INPUT_DIR="$2"
    OUTPUT_DIR="$3"
    
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    
    if [ ! -f "$ast_file" ]; then
        echo "  [SKIP] $filename (no AST)"
        return 0
    fi
    
    # Extract contract number
    contract_num=$(echo "$filename" | sed 's/batch01_contract_//; s/\.sol//')
    output_file="$OUTPUT_DIR/batch01_contract_${contract_num}_obf.sol"
    
    if [ -f "$output_file" ]; then
        echo "  [SKIP] $filename (already done)"
        return 0
    fi
    
    # Extract version and set it
    version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$sol_file" 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
    fi
    
    # Run BiAn obfuscation
    cd "$(dirname "$0")"
    python BiAn/src/main.py "$sol_file" "$ast_file" "$output_file" 2>/dev/null
    
    if [ -f "$output_file" ]; then
        echo "  [OK] $filename"
        return 0
    else
        echo "  [FAIL] $filename"
        return 1
    fi
}
export -f obfuscate_one

# Find all sol files without output
echo "[+] Finding contracts to obfuscate..."
contracts=()
for sol_file in "$INPUT_DIR"/*.sol; do
    [ -e "$sol_file" ] || continue
    filename=$(basename "$sol_file")
    ast_file="${sol_file}_json.ast"
    contract_num=$(echo "$filename" | sed 's/batch01_contract_//; s/\.sol//')
    output_file="$OUTPUT_DIR/batch01_contract_${contract_num}_obf.sol"
    
    if [ ! -f "$output_file" ] && [ -f "$ast_file" ]; then
        contracts+=("$sol_file")
    fi
done

echo "[+] Found ${#contracts[@]} contracts to obfuscate"

export INPUT_DIR OUTPUT_DIR

# Run parallel with 8 workers
printf '%s\n' "${contracts[@]}" | xargs -P 8 -I {} bash -c 'obfuscate_one "$@"' _ {}

echo ""
echo "[+] Parallel obfuscation complete!"
echo "[+] Total obfuscated: $(ls "$OUTPUT_DIR"/*.sol 2>/dev/null | wc -l)"

