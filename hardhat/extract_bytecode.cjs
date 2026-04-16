const fs = require("fs");
const path = require("path");

const artifactsPath = "./artifacts/contracts";
const outputFile = "original_bytecodes_batch05.csv";

if (!fs.existsSync(outputFile)) {
    fs.writeFileSync(outputFile, "file_name,contract_name,bytecode\n");
}

function findJsonFiles(dir) {
    let results = [];
    const files = fs.readdirSync(dir);

    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
            results = results.concat(findJsonFiles(filePath));
        } 
        else if (file.endsWith(".json") && !file.includes(".dbg")) {
            results.push(filePath);
        }
    });

    return results;
}

const jsonFiles = findJsonFiles(artifactsPath);

jsonFiles.forEach(file => {

    const data = JSON.parse(fs.readFileSync(file));

    if (data.deployedBytecode && data.deployedBytecode !== "0x") {

        const contractName = path.basename(file, ".json");

        const solFile = path.basename(
            path.dirname(file)
        );

        const bytecode = data.deployedBytecode.replace("0x","");

        const line = `${solFile},${contractName},${bytecode}\n`;

        fs.appendFileSync(outputFile, line);

        console.log("Saved:", solFile);
    }
});

console.log("Finished extracting bytecodes.");