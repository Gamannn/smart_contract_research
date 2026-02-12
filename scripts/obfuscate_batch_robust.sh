#!/bin/bash

# Robust batch obfuscation with timeout handling
# Skips contracts that take too long (> 5 minutes)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_01"
OUTPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian"

mkdir -p "$OUTPUT_DIR"

echo "[+] ==============================================="
echo "[+] BiAn Robust Batch Obfuscation (with timeouts)"
echo "[+] ==============================================="
echo "[+] Input directory: $INPUT_DIR"
echo "[+] Output directory: $OUTPUT_DIR"
echo "[+] Timeout per contract: 5 minutes"
echo ""

count=0
success=0
failed=0
skipped=0
timeout_count=0

total=$(find "$INPUT_DIR" -maxdepth 1 -name "*.sol" ! -name "*_json.ast" 2>/dev/null | wc -l)
echo "[+] Found $total contracts to process"
echo ""

for input_file in "$INPUT_DIR"/*.sol; do
    [ -e "$input_file" ] || continue
    
    filename=$(basename "$input_file")
    
    # Skip .sol_json.ast files
    if [[ "$filename" == *"_json.ast"* ]]; then
        continue
    fi
    
    # Extract contract number
    contract_num=$(echo "$filename" | sed 's/batch01_contract_//; s/\.sol//')
    output_file="$OUTPUT_DIR/batch01_contract_${contract_num}_obf.sol"
    
    # AST file path
    json_file="${input_file}_json.ast"
    
    # Skip if already done
    if [ -f "$output_file" ]; then
        echo "[$((count+1))/$total] [DONE] $filename"
        ((count++))
        continue
    fi
    
    # Skip if no AST file
    if [ ! -f "$json_file" ]; then
        echo "[$((count+1))/$total] [SKIP] $filename - No AST file"
        ((skipped++))
        ((count++))
        continue
    fi
    
    echo "[$((count+1))/$total] Processing: $filename (timeout: 5min)"
    
    # Set up solidity version
    version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$input_file" 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        solc-select use "$version" >/dev/null 2>&1
    fi
    
    # Run with timeout (5 minutes = 300 seconds)
    timeout 300 python BiAn/src/main.py "$input_file" "$json_file" "$output_file" 2>/dev/null
    
    exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        echo "    [TIMEOUT] Skipping - took longer than 5 minutes"
        ((timeout_count++))
        ((failed++))
    elif [ -f "$output_file" ]; then
        size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        echo "    [OK] $filename ($size bytes)"
        ((success++))
    else
        echo "    [FAIL] $filename"
        ((failed++))
    fi
    
    ((count++))
done

echo ""
echo "[+] ==============================================="
echo "[+] Batch obfuscation complete!"
echo "[+] Total processed: $count"
echo "[+] Successful: $success"
echo "[+] Failed: $failed"
echo "[+] Timed out: $timeout_count"
echo "[+] Skipped (no AST): $skipped"
echo "[+] Output directory: $OUTPUT_DIR"
echo "[+] ==============================================="

