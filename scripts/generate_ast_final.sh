#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_05"

cd "$INPUT_DIR" || exit 1

success=0
fail=0
total_ast=$(ls *_json.ast 2>/dev/null | wc -l)
echo "Existing ASTs: $total_ast"

for filename in *.sol; do
  json_file="${filename}_json.ast"
  if [ -s "$json_file" ]; then
    echo "[SKIP] $filename"
    continue
  fi
  
  # Detect exact version
  pragma_line=$(grep 'pragma solidity' "$filename" | head -1)
  version=$(echo "$pragma_line" | grep -oE '([0-9]+\.[0-9]+\.[0-9]+)' | head -1)
  if [ -z "$version" ]; then
    version="0.8.19"
  fi
  
  echo "Generating AST for $filename (detected: $version)"
  
  # Fallback chain: detected, 0.5.17, 0.6.12, 0.4.26, 0.8.19
  for v in "$version" "0.5.17" "0.6.12" "0.4.26" "0.8.19"; do
    solc-select use "$v" >/dev/null 2>&1
    solc --ast-json --pretty-json --overwrite "$filename" -o . >/dev/null 2>&1
    if [ -s "$json_file" ]; then
      echo "  ✓ SUCCESS with solc $v"
      ((success++))
      break
    fi
  done
  
  if [ ! -s "$json_file" ]; then
    echo "  ✗ ALL FAIL"
    ((fail++))
  fi
done

echo "[+] Final AST gen: $success new success, $fail fail"
echo "Total AST: $(ls *_json.ast | wc -l)"

