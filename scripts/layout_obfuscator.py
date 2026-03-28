import os
import glob
import json
from BiAn.src.layoutConfuse import layoutConfuse

input_dir = 'Smart-contract-obfuscation/original_contracts/batch_04'
output_dir = 'Smart-contract-obfuscation/obfuscated_contracts/layout_batch_04'
os.makedirs(output_dir, exist_ok=True)

sol_files = glob.glob(os.path.join(input_dir, 'batch04_contract_*.sol'))
ast_files = glob.glob(os.path.join(input_dir, 'batch04_contract_*.sol_json.ast'))

success = 0
for sol_file in sol_files:
    base = os.path.basename(sol_file)
    ast_file = sol_file + '_json.ast'
    
    if not os.path.exists(ast_file):
        continue
    
    obf_file = os.path.join(output_dir, base.replace('.sol', '_layout_obf.sol'))
    
    # Run layoutConfuse only
    try:
        lc = layoutConfuse(sol_file, ast_file)
        lc.run()
        
        # The output is temp_layout_confuse.sol in src dir
        temp_obf = os.path.join('BiAn/src', 'temp_layout_confuse.sol')
        if os.path.exists(temp_obf):
            os.rename(temp_obf, obf_file)
            success += 1
        print(f'SUCCESS {base}')
    except Exception as e:
        print(f'FAIL {base}: {e}')

print(f'Layout obf success: {success}/{len(ast_files)}')

# Cleanup
for f in glob.glob('BiAn/src/temp*'):
    os.remove(f)

