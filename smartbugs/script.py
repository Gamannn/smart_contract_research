import os
import json
import csv

# result folders
tool_paths = {
    "slither": "results/slither-0.11.3/20260322_1854",
    "mythril": "esults/mythril-0.24.8/20260322_1950",   # update yours
    "oyente": "results/oyente/20260322_1903",
    "osiris": "results/osiris/20260322_1904"     # update yours
}
# vulnerability mapping
vuln_map = {
    "reentrancy": "Reentrancy",
    "overflow": "Overflow",
    "underflow": "Overflow",
    "tx.origin": "Access Control",
    "access": "Access Control",
    "timestamp": "Timestamp",
    "call.value": "Low-level calls",
    "send": "Low-level calls",
    "delegatecall": "Delegatecall",
    "dos": "DoS",
    "loop": "DoS",
    "transaction order": "TOD",
    "locked ether": "Frozen Ether"
}

# output file
with open("final_results.csv", "w", newline="") as f:
    writer = csv.writer(f)
    
    header = ["Contract", "Tool", "Reentrancy", "Overflow", "Access Control", "DoS", "Delegatecall", "Timestamp", "Low-level calls", "Frozen Ether"]
    writer.writerow(header)

    for tool in tools:
        tool_path = f"results/{tool}"
        if not os.path.exists(tool_path):
            continue
        
        for root, dirs, files in os.walk(tool_path):
            for file in files:
                if file.endswith(".json"):
                    filepath = os.path.join(root, file)
                    
                    try:
                        with open(filepath) as jf:
                            data = jf.read().lower()
                    except:
                        continue
                    
                    row = [file, tool] + ["No"] * 8
                    
                    for key, val in vuln_map.items():
                        if key in data:
                            if val == "Reentrancy":
                                row[2] = "Yes"
                            elif val == "Overflow":
                                row[3] = "Yes"
                            elif val == "Access Control":
                                row[4] = "Yes"
                            elif val == "DoS":
                                row[5] = "Yes"
                            elif val == "Delegatecall":
                                row[6] = "Yes"
                            elif val == "Timestamp":
                                row[7] = "Yes"
                            elif val == "Low-level calls":
                                row[8] = "Yes"
                            elif val == "Frozen Ether":
                                row[9] = "Yes"
                    
                    writer.writerow(row)

print(" Done! Check final_results.csv")
