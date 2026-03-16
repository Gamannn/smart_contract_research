```solidity
pragma solidity ^0.4.13;

contract Database {
    address public owner;
    address public owner2;
    address public creator;
    
    mapping(address => mapping(uint256 => mapping(uint256 => bytes32))) public data;
    
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == owner2);
        _;
    }
    
    function Database() public {
        owner = address(0);
        owner2 = address(0);
        creator = msg.sender;
    }
    
    function() public payable {
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner || msg.sender == creator || msg.sender == owner2);
        owner = newOwner;
    }
    
    function changeOwner2(address newOwner2) public {
        require(msg.sender == owner || msg.sender == creator || msg.sender == owner2);
        owner2 = newOwner2;
    }
    
    function store(address user, uint256 category, uint256 index, bytes32 dataValue) public onlyOwner() {
        data[user][category][index] = dataValue;
    }
    
    function load(address user, uint256 category, uint256 index) public view returns (bytes32) {
        return data[user][category][index];
    }
    
    function transferFunds(address target, uint256 amount) public onlyOwner() {
        target.transfer(amount);
    }
}
```