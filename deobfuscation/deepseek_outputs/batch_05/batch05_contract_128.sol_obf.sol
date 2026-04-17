```solidity
pragma solidity ^0.4.23;

contract Ox605c7f677b0a162b5621193ea85b9e9f65efad68 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    
    struct Config {
        uint256 refPercent;
        uint256 refPercent2;
        address refWallet1;
        uint256 techPercent;
        address techWallet;
        uint256 adPercent;
        address adWallet;
    }
    
    Config config = Config({
        refPercent: 0,
        refPercent2: 2,
        refWallet1: 0x35580368B30742C9b6fcf859803ee7EEcED5485c,
        techPercent: 7,
        techWallet: 0x1308C144980c92E1825fae9Ab078B1CB5AAe8B23,
        adPercent: 2,
        adWallet: 0x0C7223e71ee75c6801a6C8DB772A30beb403683b
    });
    
    function getPercent(uint256 balance) private pure returns (uint256) {
        if (balance >= 3e21) {
            return 42;
        }
        if (balance >= 1e21) {
            return 40;
        }
        if (balance >= 5e20) {
            return 35;
        }
        if (balance >= 2e20) {
            return 30;
        }
        if (balance >= 1e20) {
            return 27;
        } else {
            return 25;
        }
    }
    
    function distributeFees(uint256 amount) private {
        config.techWallet.transfer(amount * config.techPercent / 100);
        config.adWallet.transfer(amount * config.adPercent / 100);
    }
    
    function extractAddress(bytes data) private pure returns (address) {
        address result;
        assembly {
            result := mload(add(data, 20))
        }
        return result;
    }
    
    function transferRefPercents(uint256 amount, address sender) private {
        if (msg.data.length != 0) {
            address referrer = extractAddress(msg.data);
            if (referrer != sender) {
                config.refWallet1.transfer(amount * config.refPercent / 100);
                referrer.transfer(amount * config.refPercent2 / 100);
            } else {
                config.refWallet1.transfer(amount * config.refPercent / 100);
            }
        } else {
            config.refWallet1.transfer(amount * config.refPercent / 100);
        }
    }
    
    function () external payable {
        if (deposits[msg.sender] != 0) {
            uint256 contractBalance = address(this).balance;
            uint256 reward = deposits[msg.sender] * getPercent(contractBalance) / 1000 * 
                           (block.number - lastBlock[msg.sender]) / 6100;
            msg.sender.transfer(reward);
        }
        
        if (msg.value > 0) {
            distributeFees(msg.value);
            transferRefPercents(msg.value, msg.sender);
        }
        
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}
```