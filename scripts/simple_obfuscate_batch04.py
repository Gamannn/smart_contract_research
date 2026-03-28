import os
import subprocess
import glob

input_dir = 'Smart-contract-obfuscation/original_contracts/batch_04'
output_dir = 'Smart-contract-obfuscation/obfuscated_contracts/bian/batch_04'
os.makedirs(output_dir, exist_ok=True)

sol_files = glob.glob(os.path.join(input_dir, 'batch04_contract_*.sol'))
ast_files = glob.glob(os.path.join(input_dir, 'batch04_contract_*.sol_json.ast'))

print(f'Found {len(sol_files)} .sol, {len(ast_files)} ASTs')

success = 0
for sol_file in sol_files:
    base = os.path.basename(sol_file)
    ast_file = sol_file + '_json.ast'
    obf_file = os.path.join(output_dir, base.replace('.sol', '_obf.sol'))
    
    if not os.path.exists(ast_file):
        print(f'SKIP {base} no AST')
        continue
    
    # Run BiAn
    cmd = ['timeout', '60', 'python3', 'BiAn/src/main.py', sol_file, ast_file]
    try:
        subprocess.run(cmd, cwd='/Users/gaman/Desktop/smart_contract_research', timeout=70, check=True)
        # Copy temp_layout_confuse.sol to obf_file
        temp_obf = '/Users/gaman/Desktop/smart_contract_research/BiAn/src/temp_layout_confuse.sol'
        if os.path.exists(temp_obf):
            os.rename(temp_obf, obf_file)
            print(f'SUCCESS {base}')
            success += 1
        else:
            print(f'SKIP {base} no temp obf')
    except:
        print(f'TIMEOUT/FAIL {base}')
        # Cleanup temp
        subprocess.run(['rm', '-f', 'BiAn/src/temp*'], cwd='/Users/gaman/Desktop/smart_contract_research')

print(f'Success: {success}/{len(ast_files)}')

