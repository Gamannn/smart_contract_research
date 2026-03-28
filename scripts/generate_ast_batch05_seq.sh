do #!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
INPUT_DIR="$PROJECT_ROOT/Smart-contract-obfuscation/original_contracts/batch_05"

cd "$INPUT_DIR" || exit 1

success=0
fail=0
for sol_file in *.sol; do
  ast_file="${sol_file}_json.ast"
  if [ -s "$ast_file" ]; then
    echo "[SKIP] $sol_file (AST exists)"
    continue
  fi
  
  # Detect version
  version=$(grep -Eo 'pragma solidity [^^;]+' "$sol_file" | sed 's/pragma solidity \ ^?//; s/\..*//' | head -1)
  [ -z "$version" ] && version="0.8.19"
  
  echo "Processing $sol_file (version $version)"
  solc-select use "$version"
  solc --ast-json --pretty-json --overwrite "$sol_file" -o . >/dev/null 2>&1
  
  if [ -s "$ast_file" ]; then
    echo "  OK $sol_file"
    ((success++))
  else
    echo "  FAIL $sol_file"
    ((fail++))
  fi
done

echo "Sequential AST gen: $success success, $fail fail. Total AST: $(ls *_json.ast | wc -l)"

