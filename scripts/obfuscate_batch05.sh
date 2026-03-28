#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_05"
OUTPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/obfuscated_contracts/bian/batch_05"
LOG_DIR="$PROJECT_ROOT/logs"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

count=0
success=0
failed=0

total=$(find "$INPUT_DIR" -maxdepth 1 -name "*.sol" ! -name "*_json.ast" 2>/dev/null | wc -l)

echo "[+] BiAn Batch Obfuscation for batch_05"
echo "[+] Found $total contracts"
echo ""

for input_file in "$INPUT_DIR"/*.sol; do
    [ -e "$input_file" ] || continue

    filename=$(basename "$input_file")

    [[ "$filename" == *"_json.ast"* ]] && continue

    contract_num=$(echo "$filename" | sed 's/batch05_contract_//; s/\\.sol//')

    output_file="$OUTPUT_DIR/batch05_contract_${contract_num}_obf.sol"
    json_file="$INPUT_DIR/${filename}_json.ast"

    log_file="$LOG_DIR/batch05_${contract_num}.log"

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
        echo "  ✓ Obfuscated"
        check_obf_versions "$output_file" >> "$log_file" 2>&1
        local obf_compat=$(tail -n1 "$log_file" | grep -o '[0-9]\+/[0-9]\+' || echo "0/6")
        echo "  Version compat: $obf_compat"
        ((success++))
    else
        echo "  ✗ Failed (see log: $log_file)"
        rm -f "$output_file"
        ((failed++))
    fi

check_obf_versions() {
    local obf_file="$1"
    local versions=("0.4.18" "0.4.26" "0.5.17" "0.6.12" "0.7.6" "0.8.19")
    local compat=0
    local total=${#versions[@]}
    
    echo "Version checks for $(basename "$obf_file"):" >> /dev/stderr
    for v in "${versions[@]}"; do
        solc-select use "$v" >/dev/null 2>&1
        if solc --ast-json "$obf_file" >/dev/null 2>&1; then
            ((compat++))
        fi
    done
    echo "Obf compat: $compat/$total" | tee -a /dev/stderr
}

    ((count++))
done

echo ""
echo "[+] DONE"
echo "Success: $success"
echo "Failed/Skipped: $failed"
echo "Total processed: $count"
