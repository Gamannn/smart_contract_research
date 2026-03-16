#!/bin/bash

# Usage: ./obfuscate_one.sh <input_sol_file> <input_json_ast_file> [output_sol_file]
# Example: ./obfuscate_one.sh contract.sol contract.sol_json.ast output.sol

INPUT_SOL=$1
INPUT_JSON=$2
OUTPUT_SOL=$3

if [ -z "$INPUT_SOL" ] || [ -z "$INPUT_JSON" ]; then
    echo "Usage: $0 <input_sol_file> <input_json_ast_file> [output_sol_file]"
    echo "  - input_sol_file: Path to the Solidity source file (.sol)"
    echo "  - input_json_ast_file: Path to the corresponding JSON AST file (.sol_json.ast)"
    echo "  - output_sol_file: (Optional) Output file name. Default: <input>_obfuscated.sol"
    exit 1
fi

if [ -z "$OUTPUT_SOL" ]; then
    OUTPUT_SOL="${INPUT_SOL%.sol}_obfuscated.sol"
fi

if [ ! -f "$INPUT_SOL" ]; then
    echo "Error: Input file $INPUT_SOL not found"
    exit 1
fi

if [ ! -f "$INPUT_JSON" ]; then
    echo "Error: JSON AST file $INPUT_JSON not found"
    exit 1
fi

pushd "/Users/gaman/Desktop/smart_contract_research/BiAn/src" > /dev/null
cp "$INPUT_SOL" temp_input.sol
cp "$INPUT_JSON" temp_input.json
python3 main.py temp_input.sol temp_input.json
cp temp_layout_confuse.sol "$OUTPUT_SOL"
popd > /dev/null
echo "[+] Obfuscation complete. Output saved to $OUTPUT_SOL"

