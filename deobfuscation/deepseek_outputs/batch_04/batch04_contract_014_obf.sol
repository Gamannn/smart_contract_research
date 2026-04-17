```solidity
pragma solidity ^0.4.18;

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    
    enum State { Active, Refunding, Closed }
    
    mapping(address => uint256) public contributions;
    address public wallet;
    State public state;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 amount);
    
    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }
    
    function contribute(address beneficiary) onlyOwner public payable {
        require(state == State.Active);
        contributions[beneficiary] = contributions[beneficiary].add(msg.value);
    }
    
    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }
    
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }
    
    function refund(address beneficiary) public {
        require(state == State.Refunding);
        uint256 amount = contributions[beneficiary];
        contributions[beneficiary] = 0;
        beneficiary.transfer(amount);
        Refunded(beneficiary, amount);
    }
}
```