#!/bin/bash
# Proper AST generation for batch_05 - auto-detect version like batch03/04, sequential in dir, fallback versions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_05"

echo "[+] Proper AST generation for batch_05"
echo "[+] Input: $INPUT_DIR"
cd "$INPUT_DIR" || exit 1

mkdir -p ../logs
success=0
skip=0
fail=0

for filename in *.sol; do
  [ -e "$filename" ] || continue
  json_file="${filename}_json.ast"
  
  if [ -s "$json_file" ]; then
    echo "[SKIP] $filename (AST exists)"
    ((skip++))
    continue
  fi
  
  # Extract version like batch03
  version=$(grep -Eo 'pragma solidity[^*]*\\K[0-9]+\\.[0-9]+\\.[0-9]+' "$filename" 2>/dev/null | head -1)
  if [ -z "$version" ]; then
    version=$(grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' "$filename" | head -1)
  fi
  if [ -z "$version" ]; then
    version="0.8.19"
  fi
  
  echo "[$((success+skip+fail+1))] $filename (version $version)"
  
  solc-select install "$version" >/dev/null 2>&1
  solc-select use "$version" >/dev/null 2>&1
  
  solc --ast-json --pretty-json --overwrite "$filename" -o . >/dev/null 2>&1
  
  if [ -s "$json_file" ]; then
    echo "  ✓ OK"
    ((success++))
  else
    echo "  ✗ FAIL"
    ((fail++))
  fi
done

echo "[+] Proper AST gen complete!"
echo "Success: $success, Skip: $skip, Fail: $fail"
echo "Total AST files: $(ls -1 *_json.ast 2>/dev/null | wc -l || echo 0)"

