#!/bin/bash

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_04"

cd "$INPUT_DIR" || exit 1

echo "[+] Generating AST in $INPUT_DIR"

count=0
missing=0

for filename in *.sol; do
  [ -e "$filename" ] || continue

  ast_file="${filename}_json.ast"
  if [ -f "$ast_file" ]; then
    continue
  fi

  version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$filename" | head -1)

  if [ -n "$version" ]; then
    solc-select install "$version" >/dev/null 2>&1
    solc-select use "$version" >/dev/null 2>&1
  fi

  echo "Generating AST for $filename"

  solc --ast-json --pretty-json --overwrite "$filename" -o . >/dev/null 2>&1

  if [ -f "$ast_file" ]; then
    echo "  ✓ $filename"
    ((count++))
  else
    echo "  ✗ $filename"
    ((missing++))
  fi
done

echo ""
echo "[+] Generated: $count"
echo "[+] Failed: $missing"
echo "[+] Total AST: $(ls *.sol_json.ast 2>/dev/null | wc -l)"

