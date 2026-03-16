```solidity
pragma solidity ^0.4.21;

contract Ownable {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max(uint64 a, uint64 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint64 a, uint64 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }
    
    function isWhitelisted(address account) public view returns(bool) {
        return whitelist[account];
    }
    
    function addToWhitelist(address account) public onlyOwner {
        whitelist[account] = true;
    }
    
    function removeFromWhitelist(address account) public onlyOwner {
        delete whitelist[account];
    }
}

interface TokenInterface {
    function balanceOf(uint tokenId) public view returns(uint);
    function transfer(address to) public payable;
}

contract TokenSale is TokenInterface, Ownable, Whitelist {
    using SafeMath for uint;
    
    mapping (address => uint) public balances;
    
    struct Config {
        uint256 price;
        uint256 commissionRate;
        address commissionWallet;
        address owner;
    }
    
    Config config = Config(0, 0, address(0), address(0));
    
    constructor(
        address commissionWallet,
        uint price,
        uint commissionRate
    ) public {
        config.commissionWallet = commissionWallet;
        config.price = price;
        config.commissionRate = commissionRate;
    }
    
    function setCommissionWallet(address commissionWallet) public onlyOwner {
        config.commissionWallet = commissionWallet;
    }
    
    function setPrice(uint price) public onlyOwner {
        config.price = price;
    }
    
    function setCommissionRate(uint commissionRate) public onlyOwner {
        config.commissionRate = commissionRate;
    }
    
    function balanceOf(uint tokenAmount) public view returns(uint) {
        return tokenAmount.mul(config.price) / (1 ether);
    }
    
    function calculateCommission(uint amount) public view returns(uint) {
        return amount.mul(config.commissionRate) / (1 ether);
    }
    
    function transfer(address recipient) public payable onlyWhitelisted {
        if(recipient == address(0)) {
            balances[config.commissionWallet] += msg.value;
        } else {
            uint commission = calculateCommission(msg.value);
            balances[recipient] += commission;
            balances[config.commissionWallet] += msg.value.sub(commission);
        }
    }
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}
```