import pandas as pd
import os

folder = "."

# 🔥 vulnerability mapping
vul_map = {
    "Reentrancy": ["reentrancy", "swc_107"],
    "Integer": ["overflow", "underflow", "swc_101"],
    "Access": ["swc_105", "swc_115", "tx.origin"],
    "TOD": ["swc_114"],
    "DoS": ["dos", "callstack"],
    "Delegatecall": ["swc_112", "delegatecall"],
    "Unchecked Call": ["swc_104", "call.value", "send"],
    "Timestamp": ["swc_116", "swc_120", "timestamp"],
    "Frozen Ether": ["swc_132", "locked"]
}

original_data = {}
obfuscated_data = {}

# 🔥 process each csv
def process_file(file):
    df = pd.read_csv(file)

    # detect tool name
    if "slither" in file:
        tool = "Slither"
    elif "mythril" in file:
        tool = "Mythril"
    elif "oyente" in file:
        tool = "Oyente"
    elif "osiris" in file:
        tool = "Osiris"
    else:
        tool = "Unknown"

    # detect dataset type
    dataset = "obfuscated" if "obfuscated" in file else "original"
    target = obfuscated_data if dataset == "obfuscated" else original_data

    for _, row in df.iterrows():
        # 🔥 get contract name (first column)
        contract = str(row.iloc[0])

        # 🔥 combine full row text
        text = " ".join(map(str, row.values)).lower()

        if contract not in target:
            target[contract] = {v: set() for v in vul_map}

        # 🔥 check vulnerabilities
        for vul, keys in vul_map.items():
            if any(k in text for k in keys):
                target[contract][vul].add(tool)

# 🔥 read only batch04 files
for file in os.listdir(folder):
    if file.endswith(".csv") and "batch02" in file:
        process_file(file)

# 🔥 build dataframe
def build_df(data):
    rows = []
    for contract, vul_data in data.items():
        row = {"Contract": contract}
        for vul in vul_map:
            tools = vul_data[vul]
            row[vul] = ", ".join(sorted(tools)) if tools else "-"
        rows.append(row)
    return pd.DataFrame(rows).sort_values("Contract")

# 🔥 save outputs
build_df(original_data).to_csv("combined_original_batch02.csv", index=False)
build_df(obfuscated_data).to_csv("combined_obfuscated_batch02.csv", index=False)

print("✅ DONE BRO 🔥")
print("Files created:")
print("combined_original_batch02.csv")
print("combined_obfuscated_batch02.csv")
