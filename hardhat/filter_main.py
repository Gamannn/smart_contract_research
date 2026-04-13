import csv
## if obfuscated change the input and output file names to the obfuscated ones
input_file = "results/batch05/original_bytecodes_batch05.csv"
output_file = "main_original_bytecodes_batch05.csv"

data = {}

with open(input_file, 'r') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        file_name = row['file_name']
        bytecode = row['bytecode']
        
        length = len(bytecode)

        # keep the largest bytecode per file
        if file_name not in data or length > len(data[file_name]['bytecode']):
            data[file_name] = row

with open(output_file, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['file_name','contract_name','bytecode'])
    writer.writeheader()
    
    for row in data.values():
        writer.writerow(row)

print("Main contracts extracted!")