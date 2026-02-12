#!/bin/bash

# Batch obfuscation script for all Solidity contracts
# This script obfuscates all .sol files in the original_contracts directory
# It automatically detects and uses the appropriate Solidity version for each contract

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_01"
OUTPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Counter for progress
count=0
success=0
failed=0
total=$(find "$INPUT_DIR" -maxdepth 1 -name "*.sol" ! -name "*_json.ast" 2>/dev/null | wc -l)

echo "[+] ==============================================="
echo "[+] BiAn Batch Obfuscation Script"
echo "[+] ==============================================="
echo "[+] Found $total contracts to obfuscate"
echo "[+] Input directory: $INPUT_DIR"
echo "[+] Output directory: $OUTPUT_DIR"
echo "[+] Solidity version: $(solc-select versions 2>/dev/null | grep current | awk '{print $1}')"
echo ""

# Process each .sol file (excluding .sol_json.ast files)
for input_file in "$INPUT_DIR"/*.sol; do
    # Skip if no files found
    [ -e "$input_file" ] || continue

    # Get just the filename without path
    filename=$(basename "$input_file")

    # Skip .sol_json.ast files
    if [[ "$filename" == *"_json.ast"* ]]; then
        continue
    fi

    # Extract contract number for output filename
    contract_num=$(echo "$filename" | sed 's/batch01_contract_//; s/\.sol//')
    output_file="$OUTPUT_DIR/batch01_contract_${contract_num}_obf.sol"

    # Set up the JSON AST file path
    json_file="$INPUT_DIR/${filename}_json.ast"

    # Check if JSON AST file exists
    if [ ! -f "$json_file" ]; then
        echo "[$((count+1))/$total] [SKIP] $filename - JSON AST file not found"
        echo "    Expected: $json_file"
        failed=$((failed+1))
        count=$((count+1))
        continue
    fi

    # Extract and use the Solidity version from the contract
    version=$(grep -Eo 'pragma solidity[^*]*\K[0-9]+\.[0-9]+\.[0-9]+' "$input_file" 2>/dev/null | head -1)
    if [ -z "$version" ]; then
        version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$input_file" | head -1)
    fi

    if [ -n "$version" ]; then
        # Try to use the detected version
        if solc-select install "$version" >/dev/null 2>&1; then
            solc-select use "$version" >/dev/null 2>&1
        fi
    fi

    echo "[$((count+1))/$total] Processing: $filename"
    echo "    Input: $input_file"
    echo "    AST: $json_file"
    echo "    Output: $output_file"

    # Run the obfuscation using the single script
    bash "$SCRIPT_DIR/obfuscate_one.sh" "$input_file" "$json_file" "$output_file" >/dev/null 2>&1

    if [ -f "$output_file" ]; then
        echo "    [✓] Obfuscated successfully"
        success=$((success+1))
    else
        echo "    [✗] Failed"
        failed=$((failed+1))
    fi

    count=$((count+1))
    echo ""
done

echo "[+] ==============================================="
echo "[+] Batch obfuscation complete!"
echo "[+] Total contracts processed: $count"
echo "[+] Successful: $success"
echo "[+] Failed/Skipped: $failed"
echo "[+] Output directory: $OUTPUT_DIR"
echo "[+] ==============================================="

