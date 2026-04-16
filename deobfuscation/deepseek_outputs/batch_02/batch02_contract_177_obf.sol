```solidity
pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract RefundableCrowdsale is Ownable {
    using SafeMath for uint256;
    
    enum State { Active, Refunding, Closed }
    
    mapping(address => uint256) public deposits;
    address public wallet;
    State public state;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 amount);
    
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }
    
    function deposit(address beneficiary) public payable {
        require(state == State.Active);
        deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    }
    
    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }
    
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }
    
    function refund(address beneficiary) public {
        require(state == State.Refunding);
        uint256 amount = deposits[beneficiary];
        deposits[beneficiary] = 0;
        beneficiary.transfer(amount);
        emit Refunded(beneficiary, amount);
    }
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [0];

struct scalar2Vector {
    address wallet;
    address owner;
}

scalar2Vector s2c = scalar2Vector(address(0), address(0));
```