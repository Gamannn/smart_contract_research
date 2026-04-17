```solidity
pragma solidity ^0.4.18;

contract TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint balance);
    function allowance(address owner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ExternalContract {
    function execute(address from, uint256 value, address to, bytes data) public;
}

contract TokenSale is ExternalContract {
    uint256 public constant tokenPrice = 100000000000000;
    TokenInterface public tokenContract;
    
    function TokenSale(address _tokenAddress) public {
        tokenContract = TokenInterface(_tokenAddress);
    }

    function buyTokens() public payable {
        uint256 tokensToBuy = calculateTokenAmount(msg.value, tokenContract.allowance(this, msg.sender));
        require(tokenContract.transferFrom(msg.sender, this, tokensToBuy));
    }

    function calculateTokenAmount(uint256 ethAmount, uint256 allowance) public view returns (uint256) {
        return Math.min(ethAmount / tokenPrice, allowance);
    }

    function () public payable {}

    function getTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(this);
    }

    function getAllowance() public view returns (uint256) {
        return tokenContract.allowance(this, msg.sender);
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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
```