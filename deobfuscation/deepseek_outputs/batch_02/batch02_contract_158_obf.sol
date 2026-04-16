```solidity
pragma solidity ^0.4.25;

interface IExternalContract {
    function() payable external;
    function deposit(address user) external payable;
    function withdraw() external;
    function balanceOf() external view returns(uint256);
    function buy() external;
    function transfer(address to, uint256 amount) external payable;
    function approve(address spender) external;
    function sell() external;
    function transferFrom(address from) external;
}

contract Ownable {
    address public owner;
    
    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract MainContract is Ownable {
    using SafeMath for uint;
    
    IExternalContract constant externalContract = IExternalContract(0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3);
    
    uint256 public contractBalance;
    
    function getExternalBalance() view public returns(uint256) {
        return externalContract.balanceOf();
    }
    
    function deposit() public payable {
        contractBalance = contractBalance.add(msg.value);
    }
    
    function snipe(address target) public {
        require(contractBalance > 0.1 ether);
        externalContract.transfer.value(1 ether)(target, 1);
    }
    
    function withdrawToWallet() public {
        externalContract.transferFrom(address(this));
    }
    
    function withdrawProfit() onlyOwner public {
        uint256 profit = address(this).balance.sub(contractBalance);
        msg.sender.transfer(profit);
    }
    
    function() external payable {}
}
```