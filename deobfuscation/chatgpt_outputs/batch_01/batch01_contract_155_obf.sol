pragma solidity ^0.4.13;

contract Database {
    address public owner;
    address public secondaryOwner;
    address public creator;
    mapping(address => mapping(uint256 => mapping(uint256 => bytes32))) public data;

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == secondaryOwner);
        _;
    }

    function() public payable { }

    function Database() public {
        owner = address(0);
        secondaryOwner = address(0);
        creator = msg.sender;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner || msg.sender == creator || msg.sender == secondaryOwner);
        owner = newOwner;
    }

    function changeSecondaryOwner(address newSecondaryOwner) public {
        require(msg.sender == owner || msg.sender == creator || msg.sender == secondaryOwner);
        secondaryOwner = newSecondaryOwner;
    }

    function storeData(address user, uint256 category, uint256 index, bytes32 dataValue) public onlyOwner {
        data[user][category][index] = dataValue;
    }

    function loadData(address user, uint256 category, uint256 index) public view returns (bytes32) {
        return data[user][category][index];
    }

    function transferFunds(address target, uint256 transferAmount) public onlyOwner {
        target.transfer(transferAmount);
    }
}