pragma solidity ^0.4.11;

contract BaseContract {
    address public owner;

    function BaseContract() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    function changeOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract TextContract is BaseContract {
    uint public cost;
    bool public isEnabled;
    event NewText(string title, string body);

    function TextContract() {
        cost = 380000000000000;
        isEnabled = true;
    }

    function updateCost(uint newCost) onlyOwner {
        cost = newCost;
        emitCostUpdated(cost);
    }

    function disableTexting() onlyOwner {
        isEnabled = false;
        emitEnabledStatus("Texting has been disabled");
    }

    function enableTexting() onlyOwner {
        isEnabled = true;
        emitEnabledStatus("Texting has been enabled");
    }

    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }

    function getCost() public view returns (uint) {
        return cost;
    }

    function sendText(string title, string body) public payable {
        if (!isEnabled) throw;
        if (msg.value < cost) throw;
        emitNewText(title, body);
    }

    function emitNewText(string title, string body) internal {
        NewText(title, body);
    }

    function emitCostUpdated(uint newCost) internal {
        // Placeholder for cost update logic
    }

    function emitEnabledStatus(string status) internal {
        // Placeholder for enabled status update logic
    }
}