```solidity
pragma solidity ^0.4.16;

interface Token {
    function transfer(address receiver, uint amount) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract KeplerTokenCrowdsale is Ownable {
    using SafeMath for uint256;
    
    uint256 public tokensPerETH;
    Token public tokenReward;
    
    event FundTransfer(address indexed beneficiary, uint256 amount, bool isContribution);
    
    function KeplerTokenCrowdsale(
        uint256 _tokensPerETH,
        address _tokenAddress
    ) public {
        tokensPerETH = _tokensPerETH.mul(130).div(125);
        tokenReward = Token(_tokenAddress);
    }
    
    function () payable public {
        require(msg.value != 0);
        uint256 amount = msg.value;
        tokenReward.transfer(msg.sender, amount.mul(tokensPerETH));
        emit FundTransfer(msg.sender, amount, true);
    }
    
    function setTokensPerETH(uint256 _tokensPerETH) onlyOwner public {
        tokensPerETH = _tokensPerETH.mul(130).div(125);
    }
    
    function withdrawETH(uint256 _amount) onlyOwner public {
        uint256 amount = _amount.mul(1 ether);
        owner.transfer(amount);
        emit FundTransfer(owner, amount, false);
    }
    
    function withdrawTokens(address _tokenAddress, uint256 _amount) onlyOwner public {
        Token token = Token(_tokenAddress);
        token.transfer(owner, _amount);
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}
```