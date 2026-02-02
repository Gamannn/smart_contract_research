#!/bin/bash

# BiAn Batch Obfuscation Script - Improved Version
# This script obfuscates all Solidity contracts in batch_01

ORIGINAL_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/original_contracts/batch_01"
OUTPUT_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/obfuscated_contracts/bian"
BIAN_SRC="/Users/gaman/Desktop/smart_contract_research/BiAn/src"

echo "=========================================="
echo "BiAn Batch Obfuscation Script"
echo "=========================================="
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Change to BiAn src directory
cd "$BIAN_SRC"

# Count files
total=$(ls -1 "$ORIGINAL_DIR"/*.sol 2>/dev/null | wc -l)
current=0
success=0
failed=""

echo "Found $total contracts to obfuscate"
echo ""

# Pre-generate all AST files first
echo "Step 1: Pre-generating AST files for all contracts..."
for sol_file in "$ORIGINAL_DIR"/*.sol; do
    if [ -f "$sol_file" ]; then
        filename=$(basename "$sol_file")
        basename_noext="${filename%.sol}"
        ast_file="$ORIGINAL_DIR/${basename_noext}.sol_json.ast"

        if [ ! -f "$ast_file" ]; then
            solc-select use 0.4.18 > /dev/null 2>&1
            solc --ast-json --pretty-json --overwrite "$sol_file" -o "$ORIGINAL_DIR" 2>/dev/null
        fi
    fi
done
echo "AST generation complete!"
echo ""

# Now obfuscate each contract
echo "Step 2: Obfuscating contracts..."
for sol_file in "$ORIGINAL_DIR"/*.sol; do
    if [ -f "$sol_file" ]; then
        ((current++))

        # Get filename without path and extension
        filename=$(basename "$sol_file")
        basename_noext="${filename%.sol}"

        # Check if AST file exists
        ast_file="$ORIGINAL_DIR/${basename_noext}.sol_json.ast"

        if [ ! -f "$ast_file" ]; then
            echo "[$current/$total] SKIP $filename (no AST file)"
            failed="$failed $filename"
            continue
        fi

        # Run obfuscation
        echo "[$current/$total] Obfuscating $filename..."

        # Run with output capture for debugging
        output=$(python3 main.py "$sol_file" "$ast_file" 2>&1)
        result=$?

        # Copy output to destination
        if [ -f "temp_layout_confuse.sol" ]; then
            mv "temp_layout_confuse.sol" "$OUTPUT_DIR/${basename_noext}_obf.sol"
            echo "  → Saved to ${basename_noext}_obf.sol"
            ((success++))
        elif [ $result -ne 0 ]; then
            echo "  ✗ Failed (exit code: $result)"
            failed="$failed ${basename_noext}"
        fi

        # Clean up temp files
        rm -f temp.sol temp.sol_json.ast 2>/dev/null
    fi
done

echo ""
echo "=========================================="
echo "Batch obfuscation complete!"
echo "Total: $total | Success: $success | Failed: $(echo $failed | wc -w)"
echo "Output directory: $OUTPUT_DIR"
echo "=========================================="

if [ -n "$failed" ]; then
    echo ""
    echo "Failed contracts:$failed"
fi

