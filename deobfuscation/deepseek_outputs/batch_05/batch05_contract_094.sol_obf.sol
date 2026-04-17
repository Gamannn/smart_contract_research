pragma solidity ^0.4.11;

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Casino is Ownable {
    uint256 public startBalance;
    uint256 public constant MIN_BALANCE = 0.1 ether; // Assuming Ox5f9bfa91dd87bc6f18c20468b1f57618bd17e2ed is 0.1 ether

    function play(address player, uint256 bet) payable onlyOwner {
        require(msg.value > 0);
        startBalance = this.balance;
        player.call.value(msg.value)(bytes4(keccak256("play(uint256)")), bet);
        if (this.balance <= MIN_BALANCE) revert();
        owner.transfer(this.balance);
    }

    function withdraw() onlyOwner {
        require(this.balance > 0);
        owner.transfer(this.balance);
    }

    function () payable {}
}