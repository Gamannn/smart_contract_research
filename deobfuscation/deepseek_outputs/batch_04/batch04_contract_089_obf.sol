```solidity
pragma solidity ^0.4.21;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
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

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    
    function unpause() onlyOwner public {
        paused = false;
        emit Unpause();
    }
}

contract Destructible is Pausable {
    constructor() public payable {}
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
    
    function destroyAndSend(address recipient) onlyOwner public {
        selfdestruct(recipient);
    }
}

contract TokenSale is Destructible {
    event PurchaseToken(address indexed buyer, uint256 tokens, uint256 value);
    
    uint256 public tokenPrice = 250000000000000;
    IERC20 public token;
    
    using SafeMath for uint256;
    
    uint256 public constant decimals = 18;
    uint256 public etherRaised;
    
    constructor() public {
        tokenPrice = 250000000000000;
    }
    
    function() public whenNotPaused payable {
        require(msg.value > 0);
        uint256 tokens = (msg.value * (10 ** decimals)).div(tokenPrice);
        token.transfer(msg.sender, tokens);
        etherRaised = etherRaised.add(msg.value);
        emit PurchaseToken(msg.sender, tokens, msg.value);
    }
    
    function withdrawAll(address recipient) public onlyOwner {
        require(etherRaised > 0);
        recipient.transfer(etherRaised);
        etherRaised = 0;
    }
    
    function withdrawAmount(address recipient, uint256 amount) public onlyOwner {
        require(etherRaised > amount);
        recipient.transfer(amount);
        etherRaised = etherRaised.sub(amount);
    }
}
```