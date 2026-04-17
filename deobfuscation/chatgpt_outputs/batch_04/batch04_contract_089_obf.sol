```solidity
pragma solidity ^0.4.21;

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
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

    function pause() onlyOwner public {
        paused = true;
        emit Pause();
    }
}

contract Destructible is Pausable {
    function Destructible() public payable {}

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address recipient) onlyOwner public {
        selfdestruct(recipient);
    }
}

contract TokenSale is Destructible {
    using SafeMath for uint256;

    event PurchaseToken(address indexed purchaser, uint256 value, uint256 amount);

    uint public rate = 250000000000000;
    Token public token;
    uint256 public constant decimals = 18;
    uint256 public etherRaised;

    function TokenSale(address _tokenAddress) public {
        token = Token(_tokenAddress);
    }

    function() public whenNotPaused payable {
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(10 ** decimals).div(rate);
        token.transfer(msg.sender, tokens);
        etherRaised = etherRaised.add(msg.value);
    }

    function withdrawEther(address to) public onlyOwner {
        require(etherRaised > 0);
        to.transfer(etherRaised);
        etherRaised = 0;
    }

    function withdrawPartialEther(address to, uint256 amount) public onlyOwner {
        require(etherRaised > amount);
        to.transfer(amount);
        etherRaised = etherRaised.sub(amount);
    }
}
```