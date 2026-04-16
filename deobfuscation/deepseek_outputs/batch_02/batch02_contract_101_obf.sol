```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract HeartContract {
    using SafeMath for uint256;
    
    address public contractOwner;
    address public currentLeader;
    
    mapping(uint256 => uint256) public heartBalances;
    
    constructor() public {
        contractOwner = msg.sender;
    }
    
    function withdrawOwnerFunds() public {
        require(msg.sender == contractOwner);
        contractOwner.transfer(address(this).balance);
    }
    
    function sendHeart(uint256 heartId) public payable {
        require(msg.value > 1900000000000000);
        
        heartBalances[heartId] = heartBalances[heartId].add(msg.value);
        currentLeader.transfer(msg.value.div(2));
        currentLeader = msg.sender;
    }
    
    function getTotalHeartsByAddress(uint256 heartId) public view returns(uint256) {
        return heartBalances[heartId];
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
```