#!/bin/bash

# Batch obfuscation script for batch_03
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_03"
OUTPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian/batch_03"

# Create output directory
mkdir -p "$OUTPUT_DIR"

count=0
success=0
failed=0
total=$(find "$INPUT_DIR" -maxdepth 1 -name "*.sol" ! -name "*_json.ast" 2>/dev/null | wc -l)

echo "[+] BiAn Batch Obfuscation for batch_03"
echo "[+] Found $total contracts"
echo "[+] Input: $INPUT_DIR"
echo "[+] Output: $OUTPUT_DIR"
echo ""

for input_file in "$INPUT_DIR"/*.sol; do
    [ -e "$input_file" ] || continue

    filename=$(basename "$input_file")

    if [[ "$filename" == *"_json.ast"* ]]; then
        continue
    fi

    contract_num=$(echo "$filename" | sed 's/batch03_contract_//; s/\.sol//')
    output_file="$OUTPUT_DIR/batch03_contract_${contract_num}_obf.sol"

    json_file="$INPUT_DIR/${filename}_json.ast"

    if [ ! -f "$json_file" ]; then
        echo "[$((count+1))/$total] [SKIP] $filename - no AST"
        failed=$((failed+1))
        count=$((count+1))
        continue
    fi

    version=$(grep -Eo 'pragma solidity[^*]*\K[0-9]+\.[0-9]+\.[0-9]+' "$input_file" 2>/dev/null | head -1)
    if [ -z "$version" ]; then
        version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$input_file" | head -1)
    fi

    if [ -n "$version" ]; then
        solc-select install "$version" >/dev/null 2>&1
        solc-select use "$version" >/dev/null 2>&1
    fi

    echo "[$((count+1))/$total] $filename → $output_file"

    bash "$SCRIPT_DIR/obfuscate_one.sh" "$input_file" "$json_file" "$output_file" >/dev/null 2>&1

    if [ -f "$output_file" ]; then
        echo "  [✓]"
        success=$((success+1))
    else
        echo "  [✗]"
        failed=$((failed+1))
    fi

    count=$((count+1))
done

echo "[+] Complete! Success: $success, Failed/Skipped: $failed / $count"
