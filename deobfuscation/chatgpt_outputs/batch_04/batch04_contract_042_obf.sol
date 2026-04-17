```solidity
pragma solidity ^0.4.24;

contract TokenInterface {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance) {}
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
    function approve(address spender, uint256 value) returns (bool success) {}
    function allowance(address owner, address spender) constant returns (uint256 remaining) {}
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    uint256 public price = 1;
    StandardToken public tokenContract;

    constructor(uint256 initialPrice, StandardToken tokenAddress) public {
        price = initialPrice;
        tokenContract = tokenAddress;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Invalid price");
        price = newPrice;
    }

    function () public payable {
        require(msg.value > 0, "No ETH received");
        buyTokens(msg.sender);
    }

    function calculateTokens(uint256 ethAmount, uint256 tokenPrice) internal pure returns (uint256) {
        uint256 tokens = ethAmount * tokenPrice;
        assert(ethAmount == 0 || tokens / ethAmount == tokenPrice);
        return tokens;
    }

    function buyTokens(address beneficiary) public payable {
        uint256 tokens = calculateTokens(msg.value, price);
        tokenContract.transfer(beneficiary, tokens);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
```