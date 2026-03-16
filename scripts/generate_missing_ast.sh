#!/bin/bash

INPUT_DIR="../Smart-contract-obfuscation/original_contracts/batch_02"

success=0
failed=0
skipped=0

for sol in $INPUT_DIR/*.sol; do

    ast="${sol}_json.ast"

    # Skip if AST already exists
    if [[ -f "$ast" ]]; then
        ((skipped++))
        continue
    fi

    # Extract pragma version
    pragma=$(grep -m1 "pragma solidity" "$sol" | sed -E 's/.*solidity\s+([^;]+);/\1/')

    # Remove symbols ^ >= <=
    version=$(echo "$pragma" | sed 's/[^0-9\.]//g')

    echo "Processing $sol (pragma: $version)"

    solc-select use $version >/dev/null 2>&1

    solc --ast-json "$sol" > "$ast" 2>/dev/null

    if [[ -s "$ast" ]]; then
        echo "✓ AST generated"
        ((success++))
    else
        echo "✗ Failed"
        ((failed++))
        rm -f "$ast"
    fi

done

echo "--------------------------------"
echo "Generated AST: $success"
echo "Failed: $failed"
echo "Skipped (already exist): $skipped"