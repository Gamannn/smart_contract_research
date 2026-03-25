#!/bin/bash

INPUT_DIR="Smart-contract-obfuscation/original_contracts/batch_03"
OUTPUT_DIR="$INPUT_DIR"
cd "$(dirname "$0")/.."

echo "[+] Fixed Sequential AST Generation for Batch_03 - All Versions"

generate_ast_fixed() {
  sol_file="$1"
  filename=$(basename "$sol_file")
  ast_file="${sol_file%.sol}.sol_json.ast"
  
  if [ -f "$ast_file" ]; then
    return
  fi
  
  cd "$INPUT_DIR"
  
  # Try multiple compilers
  for v in 0.8.20 0.7.0 0.6.12 0.5.17 0.4.26 0.4.24 0.4.18; do
    solc-select use "$v" >/dev/null 2>&1
    if solc --ast-json --pretty-json --overwrite "$filename" -o . 2>/dev/null && [ -s "$ast_file" ]; then
      echo "  ✓ $filename ($v)"
      return
    fi
  done
  
  echo "  ✗ $filename (all compilers failed)"
}

export -f generate_ast_fixed

for sol_file in "$INPUT_DIR"/*.sol; do
  generate_ast_fixed "$sol_file"
done

echo "[+] Total AST: $(ls "$INPUT_DIR"/*.sol_json.ast 2>/dev/null | wc -l)"
