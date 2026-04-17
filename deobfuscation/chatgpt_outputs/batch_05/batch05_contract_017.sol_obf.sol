pragma solidity ^0.4.18;

contract TokenInterface {
    function totalSupply() constant public returns (uint totalSupply);
    function balanceOf(address owner) constant public returns (uint balance);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function allowance(address owner, address spender) constant public returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    address public constant tokenAddress = 0x0;
    TokenInterface public token;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public constant share1 = 5;
    uint256 public constant share2 = 21;
    uint256 public constant share3 = 1000;
    address public constant payee1 = 0xd58f863De3bb877F24996291cC3C659b3550d58e;
    address public constant payee2 = 0x4dF46817dc0e8dD69D7DA51b0e2347f5EFdB9671;
    address public constant payee3 = 0x8b0e368aF9d27252121205B1db24d9E48f62B236;
    address public constant payee4 = 0x574c4DB1E399859753A09D65b6C5586429663701;

    function TokenSale() public {
        token = TokenInterface(tokenAddress);
    }

    function buyTokens() payable public {
        uint256 amount = msg.value / buyPrice;
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 refund = 0;
        uint256 totalCost = amount * buyPrice;

        if (msg.value > totalCost) {
            refund = msg.value - totalCost;
        }

        if (refund > 0) {
            require(msg.sender.send(refund));
        }

        if (amount > tokenBalance) {
            require(token.transfer(msg.sender, amount));
        } else {
            require(payee1.send(msg.value * share1 / 100));
            require(payee2.send(msg.value * share2 / 100));
            require(payee3.send(msg.value * share3 / 1000));
        }

        GotTokens(msg.sender, msg.value, amount);
    }

    function () payable public {
        buyTokens();
    }

    event GotTokens(address indexed buyer, uint256 value, uint256 amount);
}