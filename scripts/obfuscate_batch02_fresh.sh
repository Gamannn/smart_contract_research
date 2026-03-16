#!/bin/bash

# BiAn Batch Obfuscation Script for batch_02 - Fresh 100% Run
# Absolute paths, generates missing ASTs, robust temp handling

ORIGINAL_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/original_contracts/batch_02"
OUTPUT_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/obfuscated_contracts/bian/batch_02"
BIAN_SRC="/Users/gaman/Desktop/smart_contract_research/BiAn/src"

echo "=========================================="
echo "BiAn Batch_02 Fresh Obfuscation - 100% Target"
echo "=========================================="
echo "Original: $ORIGINAL_DIR"
echo "Output: $OUTPUT_DIR"
echo "BiAn: $BIAN_SRC"
echo ""

mkdir -p "$OUTPUT_DIR"

# Count totals
total_sol=$(ls -1 "$ORIGINAL_DIR"/*.sol 2>/dev/null | wc -l)
total_ast=$(ls -1 "$ORIGINAL_DIR"/*.sol_json.ast 2>/dev/null | wc -l)
missing_ast=$((total_sol - total_ast))

echo "Found: $total_sol contracts | $total_ast ASTs | Missing ASTs: $missing_ast"
echo ""

cd "$BIAN_SRC" || { echo "Failed to cd to BiAn/src"; exit 1; }

# Step 1: Generate missing ASTs with solc 0.4.18 (common for batch_02)
echo "Step 1: Generating $missing_ast missing AST files..."
ast_generated=0
ast_failed=0
for sol_file in "$ORIGINAL_DIR"/*.sol; do
    if [ -f "$sol_file" ]; then
        filename=$(basename "$sol_file")
        basename_noext=${filename%.sol}
        ast_file="$ORIGINAL_DIR/${basename_noext}.sol_json.ast"

        if [ ! -f "$ast_file" ]; then
            echo "Generating AST for $filename..."
            solc-select use 0.4.18 >/dev/null 2>&1
            solc --ast-json --pretty-json --overwrite "$sol_file" -o "$ORIGINAL_DIR" >/dev/null 2>&1

        if [ -f "$ast_file" ] && [ -s "$ast_file" ]; then
                echo "  ✓ $filename"
                ((ast_generated++))
            else
                echo "  ✗ $filename (empty/invalid)"
                ((ast_failed++))
            fi
        fi
    fi
done
echo "AST generation: $ast_generated generated | $ast_failed failed"
echo ""

# Recount ASTs
total_ast=$(ls -1 "$ORIGINAL_DIR"/*.sol_json.ast 2>/dev/null | wc -l)
echo "Total ASTs now: $total_ast/$total_sol"
echo ""

# Step 2: Obfuscate all with valid ASTs
echo "Step 2: Obfuscating $total_ast contracts..."
success=0
failed=0
current=0

for sol_file in "$ORIGINAL_DIR"/*.sol; do
    if [ -f "$sol_file" ]; then
        ((current++))
        filename=$(basename "$sol_file")
        basename_noext=${filename%.sol}
        ast_file="$ORIGINAL_DIR/${basename_noext}.sol_json.ast"
        obf_file="$OUTPUT_DIR/${basename_noext}_obf.sol"

        if [ ! -f "$ast_file" ] || [ ! -s "$ast_file" ]; then
            echo "[$current/$total_sol] SKIP $filename (no valid AST)"
            ((failed++))
            continue
        fi

        echo "[$current/$total_sol] Obfuscating $filename..."

        # Clear any old temps
        rm -f temp_input.* temp.sol temp.sol_json.ast temp_layout_confuse.sol

        # Copy inputs
        cp "$sol_file" temp.sol
        cp "$ast_file" temp.json
        cp "$ast_file" temp.sol_json.ast

        # Run BiAn
        python3 main.py temp.sol temp.json >/dev/null 2>&1
        result=$?

        # Check output
        if [ -f "temp_layout_confuse.sol" ] && [ -s "temp_layout_confuse.sol" ]; then
            mv "temp_layout_confuse.sol" "$obf_file"
            echo "  ✓ Success: $basename_noext_obf.sol ($(( $(stat -f%z "$obf_file") / 1000 ))KB)"
            ((success++))
        else
            echo "  ✗ Failed: temp_layout_confuse.sol missing/empty (code: $result)"
            ((failed++))
        fi

        # Final cleanup
        rm -f temp_input.* temp.sol temp.sol_json.ast
    fi
done

echo ""
echo "=========================================="
echo "COMPLETE! Total: $total_sol | ASTs: $total_ast | Success: $success | Failed: $failed"
echo "Obfuscated files: $OUTPUT_DIR"
echo "=========================================="

if [ $success -eq $total_sol ]; then
    echo "🎉 100% SUCCESS!"
else
    echo "⚠️  Some failures - check logs above."
fi
