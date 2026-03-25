#!/bin/bash

# Fixed BiAn Batch Obfuscation Script for batch_03 - Fresh 100% Run (Absolute paths, no quotes)
# Generates missing ASTs first, then obfuscates all possible using BiAn tool

ORIGINAL_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/original_contracts/batch_03"
OUTPUT_DIR="/Users/gaman/Desktop/smart_contract_research/Smart-contract-obfuscation/obfuscated_contracts/batch_03"
BIAN_SRC="/Users/gaman/Desktop/smart_contract_research/BiAn/src"

echo "=========================================="
echo "BiAn Batch_03 Fresh Obfuscation - Automated Full Coverage"
echo "=========================================="
echo "Original: $ORIGINAL_DIR"
echo "Output: $OUTPUT_DIR"
echo "BiAn: $BIAN_SRC"
echo ""
mkdir -p "$OUTPUT_DIR"

PROJECT_ROOT="/Users/gaman/Desktop/smart_contract_research"

# Step 0: Count totals
total_sol=$(find \"$ORIGINAL_DIR\" -maxdepth 1 -name '*.sol' ! -name '*_json.ast' | wc -l)
echo \"Total .sol contracts: $total_sol\"

cd "$BIAN_SRC" || { echo "Failed to cd to BiAn/src"; exit 1; }

# Step 1: Generate missing ASTs (sequential for reliability)
echo "Step 1: Generating missing ASTs..."
ast_generated=0
ast_failed=0
for sol_file in "$ORIGINAL_DIR"/*.sol; do
  if [[ "$sol_file" == *"_json.ast" ]]; then continue; fi
  ast_file="${sol_file%.*}.sol_json.ast"
  if [ ! -f "$ast_file" ]; then
    filename=$(basename "$sol_file")
    version=$(grep -oE '[0-9.]+' "$sol_file" | head -1 || echo '0.8.20')
    solc-select use "$version" >/dev/null 2>&1
    pushd "$ORIGINAL_DIR" >/dev/null
    solc --ast-json --pretty-json --overwrite "$filename" -o . >/dev/null 2>&1
    popd >/dev/null
    if [ -f "$ast_file" ] && [ -s "$ast_file" ]; then
      ((ast_generated++))
      echo "  ✓ AST: $filename"
    else
      ((ast_failed++))
      echo "  ✗ AST: $filename"
    fi
  fi
done
echo "AST summary: $ast_generated generated | $ast_failed failed"

# Step 2: Obfuscate all contracts with ASTs
echo \"Step 2: Obfuscating all contracts with ASTs...\"
success=0
failed=0
current=0

for sol_file in "$ORIGINAL_DIR"/*.sol; do
  if [[ "$sol_file" == *"_json.ast" ]]; then continue; fi
  ((current++))
  filename=$(basename "$sol_file")
  basename_noext=${filename%.sol}
  ast_file="$ORIGINAL_DIR/${basename_noext}.sol_json.ast"
  obf_file="$OUTPUT_DIR/${basename_noext}_obf.sol"

  echo \"[$current/$total_sol] $filename\"

  if [ ! -f \"$ast_file\" ] || [ ! -s \"$ast_file\" ]; then
    echo \"  SKIP (no AST)\"
    ((failed++))
    continue
  fi

  # Clear temps
  rm -f temp*.sol temp*.json temp_layout_confuse.sol

  # Copy
  cp \"$sol_file\" temp.sol
  cp \"$ast_file\" temp.json
  cp \"$ast_file\" temp.sol_json.ast

  # Run BiAn
  python3 main.py temp.sol temp.json >/dev/null 2>&1

  # Check
  if [ -f \"temp_layout_confuse.sol\" ] && [ -s \"temp_layout_confuse.sol\" ]; then
    cp \"temp_layout_confuse.sol\" \"$obf_file\"
    echo \"  ✓ $(stat -f%z \"$obf_file\" 2>/dev/null | awk '{print int($1/1024) \"KB\"}')\"
    ((success++))
  else
    echo \"  ✗ Failed\"
    ((failed++))
  fi

  # Cleanup
  rm -f temp*.sol temp*.json temp_layout_confuse.sol
done

echo \"\"
echo \"==========================================\"
echo \"COMPLETE! Success: $success | Failed/Skipped: $failed | Total: $total_sol\"
echo \"Files in: $OUTPUT_DIR\"
echo \"==========================================\"
