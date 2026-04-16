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

contract TokenSaleInterface {
    function buyTokens(address buyer, uint256 amount, address referrer, bytes data) public;
}

contract TokenSale is TokenSaleInterface {
    uint256 public constant TOKEN_PRICE = 100000000000000;
    TokenInterface public tokenContract;
    event BoughtToken(uint amount, address indexed buyer);
    event SoldToken(uint amount, uint value, address indexed seller);

    function TokenSale(address tokenAddress) public {
        tokenContract = TokenInterface(tokenAddress);
    }

    function buyTokens(address buyer, uint256 amount, address referrer, bytes data) public {
        require(tokenContract.act());
        require(msg.sender == referrer);
        uint256 tokenAmount = calculateTokenAmount(amount);
        tokenContract.transferFrom(buyer, this, amount);
        buyer.transfer(tokenAmount);
        emit SoldToken(amount, tokenAmount, buyer);
    }

    function () public payable {
        require(tokenContract.act());
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        tokenContract.transfer(msg.sender, tokenAmount);
        emit BoughtToken(tokenAmount, msg.value, msg.sender);
    }

    function calculateTokenAmount(uint256 value) public view returns (uint256) {
        return value / TOKEN_PRICE;
    }

    function getTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(this);
    }

    function getTokenAllowance() public view returns (uint256) {
        return tokenContract.allowance(this, msg.sender);
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

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getAddrFunc(uint256 index) internal view returns(address payable) {
    return _address_constant[index];
}

uint256[] public _integer_constant = [0, 100000000000000, 50000000000000];
address payable[] public _address_constant = [0x5BD574410F3A2dA202bABBa1609330Db02aD64C2];