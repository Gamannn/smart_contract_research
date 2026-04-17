```solidity
pragma solidity ^0.4.18;

contract TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint balance);
    function allowance(address owner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    bool public act;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenReceiver {
    function receiveApproval(address from, uint256 value, address token, bytes data) public;
}

contract TokenSale is TokenReceiver {
    uint256 public constant TOKEN_PRICE = 100000000000000;
    TokenInterface public tokenContract;
    address public owner;
    event BoughtToken(uint amount, uint cost, address indexed buyer);
    event SoldToken(uint amount, uint revenue, address indexed seller);

    function TokenSale(address _tokenContract) public {
        tokenContract = TokenInterface(_tokenContract);
        owner = msg.sender;
    }

    function receiveApproval(address from, uint256 value, address token, bytes data) public {
        require(tokenContract.act());
        require(msg.sender == owner);
        uint256 tokenAmount = calculateTokenSell(value);
        tokenContract.transferFrom(from, this, value);
        from.transfer(tokenAmount);
        emit SoldToken(value, tokenAmount, from);
    }

    function buyTokens() public payable {
        require(tokenContract.act());
        uint256 tokenAmount = calculateTokenBuy(msg.value, tokenContract.balanceOf(this));
        tokenContract.transfer(msg.sender, tokenAmount);
        emit BoughtToken(tokenAmount, msg.value, msg.sender);
    }

    function calculateTokenBuy(uint256 ethAmount, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(ethAmount, contractBalance, tokenContract.totalSupply());
    }

    function calculateTokenSell(uint256 tokenAmount) public view returns (uint256) {
        return calculateTrade(tokenAmount, tokenContract.balanceOf(this), tokenContract.totalSupply());
    }

    function calculateTrade(uint256 tradeAmount, uint256 reserveBalance, uint256 totalSupply) public pure returns (uint256) {
        return (tradeAmount * totalSupply) / (reserveBalance + tradeAmount);
    }

    function() public payable {}

    function getBalance() public view returns (uint256) {
        return tokenContract.balanceOf(this);
    }

    function getTotalSupply() public view returns (uint256) {
        return tokenContract.totalSupply();
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
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

function getAddrFunc(uint256 index) internal view returns(address payable) {
    return _address_constant[index];
}

struct Scalar2Vector {
    address owner;
    uint256 totalSupply;
    uint256 tokenPrice;
    bool act;
}

Scalar2Vector s2c = Scalar2Vector(address(0), 0, 0, false);

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

address payable[] public _address_constant = [0x96357e75B7Ccb1a7Cf10Ac6432021AEa7174c803];
uint256[] public _integer_constant = [0, 100000000000000, 50000000000000];
```