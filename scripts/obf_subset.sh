#!/bin/bash

# Obfuscate first 50 with layout only (fast, no dataflow hang)
mkdir -p obfuscated_contracts/bian/batch_04_subset

for i in {1..50}; do
  sol="Smart-contract-obfuscation/original_contracts/batch_04/batch04_contract_${i: -3}.sol"
  ast="${sol}_json.ast"
  obf="obfuscated_contracts/bian/batch_04_subset/batch04_contract_${i: -3}_obf.sol"
  
  if [ -f "$ast" ]; then
    # Run layoutConfuse only
    cp "$sol" BiAn/src/temp.sol
    cp "$ast" BiAn/src/temp.sol_json.ast
    cd BiAn/src
    sed -i '' 's/dataflowObfuscation/# dataflowObfuscation/g' main.py
    timeout 120 python3 main.py temp.sol temp.sol_json.ast "$obf"
    cd ../..
    rm -f BiAn/src/temp*
    sed -i '' 's/# dataflowObfuscation/dataflowObfuscation/g' BiAn/src/main.py
    echo "Done $i ✓"
  fi
done

ls obfuscated_contracts/bian/batch_04_subset/*_obf.sol | wc -l

