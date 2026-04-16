```solidity
pragma solidity ^0.4.25;

interface IExternalContract {
    function() payable external;
    function offer(address recipient) external payable;
    function withdraw() external;
    function getBalance() external view returns(uint256);
    function initialize() external;
    function invest(address investor) external payable;
    function setOwner(address newOwner) external;
    function finalize() external;
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
    
    IExternalContract constant externalContract = IExternalContract(0xb172BB8BAae74F27Ade3211E0c145388d3b4f8d8);
    uint256 public contractBalance;
    
    function getExternalBalance() view public returns(uint256) {
        return externalContract.getBalance();
    }
    
    function getContractBalance() view public returns(uint256) {
        return contractBalance;
    }
    
    function deposit() public payable {
        contractBalance = contractBalance.add(msg.value);
    }
    
    function invest(address investor) public {
        require(contractBalance > 0.1 ether);
        contractBalance = contractBalance.sub(0.1 ether);
        externalContract.offer.value(0.1 ether)(investor);
        externalContract.initialize();
    }
    
    function withdrawExternal() public {
        externalContract.withdraw();
    }
    
    function withdrawContract() public onlyOwner {
        uint256 amount = address(this).balance.sub(contractBalance);
        msg.sender.transfer(amount);
    }
    
    function() external payable {}
}
```