#!/bin/bash

BATCH_DIR="batch_04"

INPUT_DIR="Smart-contract-obfuscation/original_contracts/$BATCH_DIR"
OUTPUT_DIR="Smart-contract-obfuscation/obfuscated_contracts/bian/$BATCH_DIR"
mkdir -p "$OUTPUT_DIR"

obfuscate_one_parallel() {
    input_file="$1"
    json_file="$2"
    output_file="$3"
    filename=$(basename "$input_file")
    
    timeout 20 bash scripts/obfuscate_one.sh "$input_file" "$json_file" "$output_file" || echo "Timeout $filename"
}

export -f obfuscate_one_parallel

sol_files=()
ast_files=()

for f in "$INPUT_DIR"/*.sol; do
    sol_files+=("$f")
    ast="${f}_json.ast"
    if [ -f "$ast" ]; then
        ast_files+=("$ast")
    fi
done

echo "Processing ${#sol_files[@]} files, ${#ast_files[@]} with AST"

for ((i=0; i<${#ast_files[@]}; i++)); do
    filename=$(basename "${sol_files[$i]}")
    num=$(echo "$filename" | sed 's/batch04_contract_//;s/\.sol//')
    out="$OUTPUT_DIR/batch04_contract_${num}_obf.sol"
    xargs -n1 -P 4 -I {} bash -c 'obfuscate_one_parallel "$@"' _ "${sol_files[$i]}" "${ast_files[$i]}" "$out" &
done
wait

echo "Obfuscation complete for $BATCH_DIR"
ls "$OUTPUT_DIR"/*_obf.sol | wc -l

