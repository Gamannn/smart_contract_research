```solidity
pragma solidity ^0.4.15;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    
    function transfer(address to, uint256 value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) constant returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
        var allowance = allowed[from][msg.sender];
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256) {
        return allowed[owner][spender];
    }
}

contract Auction is Ownable {
    using SafeMath for uint256;
    
    enum States { Setup, AcceptingBids, Paused, Ended }
    States public state = States.Setup;
    
    address public highestBidder;
    uint256 public highestBid;
    
    mapping(address => uint256) pendingReturns;
    
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionStarted();
    event AuctionPaused();
    event AuctionResumed();
    event AuctionEnded(address winner, uint256 amount);
    
    modifier inState(States expectedState) {
        require(state == expectedState);
        _;
    }
    
    modifier notInState(States excludedState) {
        require(state != excludedState);
        _;
    }
    
    function bid() payable inState(States.AcceptingBids) {
        require(msg.value > highestBid);
        
        if (highestBid != 0) {
            pendingReturns[highestBidder] = pendingReturns[highestBidder].add(highestBid);
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }
    
    function withdraw() notInState(States.Ended) returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function startAuction() onlyOwner inState(States.Setup) {
        state = States.AcceptingBids;
        AuctionStarted();
    }
    
    function pauseAuction() onlyOwner inState(States.AcceptingBids) {
        state = States.Paused;
        AuctionPaused();
    }
    
    function resumeAuction() onlyOwner inState(States.Paused) {
        state = States.AcceptingBids;
        AuctionResumed();
    }
    
    function endAuction() onlyOwner notInState(States.Ended) {
        state = States.Ended;
        AuctionEnded(highestBidder, highestBid);
        owner.transfer(highestBid);
    }
}

contract TulipToken is Auction, StandardToken {
    string public constant name = "TulipToken";
    string public constant symbol = "TLP";
    uint8 public constant decimals = 0;
    uint256 public constant INITIAL_SUPPLY = 1;
    
    function TulipToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }
}
```