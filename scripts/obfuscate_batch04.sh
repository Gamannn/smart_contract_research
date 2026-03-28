#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_04"
OUTPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian/batch_04"
LOG_DIR="$PROJECT_ROOT/logs"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

count=0
success=0
failed=0

total=$(find "$INPUT_DIR" -maxdepth 1 -name "*.sol" ! -name "*_json.ast" 2>/dev/null | wc -l)

echo "[+] BiAn Batch Obfuscation for batch_04"
echo "[+] Found $total contracts"
echo ""

for input_file in "$INPUT_DIR"/*.sol; do
    [ -e "$input_file" ] || continue

    filename=$(basename "$input_file")

    [[ "$filename" == *"_json.ast"* ]] && continue

    contract_num=$(echo "$filename" | sed 's/batch04_contract_//; s/\.sol//')

    output_file="$OUTPUT_DIR/batch04_contract_${contract_num}_obf.sol"
    json_file="$INPUT_DIR/${filename}_json.ast"

    log_file="$LOG_DIR/batch04_${contract_num}.log"

    # Skip if no AST
    if [ ! -f "$json_file" ]; then
        echo "[$((count+1))/$total] SKIP $filename (no AST)"
        ((failed++))
        ((count++))
        continue
    fi

    echo "[$((count+1))/$total] Processing $filename"

    # Run obfuscation with timeout + logging
    /opt/homebrew/bin/gtimeout 180 bash "$SCRIPT_DIR/obfuscate_one.sh" \
        "$input_file" "$json_file" "$output_file" \
        > "$log_file" 2>&1

    # Check result properly
    if [[ -s "$output_file" ]]; then
        echo "  ✓ Success"
        ((success++))
    else
        echo "  ✗ Failed (see log: $log_file)"
        rm -f "$output_file"
        ((failed++))
    fi

    ((count++))
done

echo ""
echo "[+] DONE"
echo "Success: $success"
echo "Failed/Skipped: $failed"
echo "Total processed: $count"