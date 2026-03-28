#!/bin/bash

sol="$1"
ast="$2"
out="$3"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/BiAn/src" || exit

cp "$sol" temp.sol
cp "$ast" temp.sol_json.ast

python3 main.py temp.sol temp.sol_json.ast

# IMPORTANT: capture BiAn output
if [[ -f temp_layout_confuse.sol ]]; then
    cp temp_layout_confuse.sol "$out"
fi

rm -f temp.sol temp.sol_json.ast temp_layout_confuse.sol