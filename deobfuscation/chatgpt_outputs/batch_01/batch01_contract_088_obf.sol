```solidity
pragma solidity ^0.4.19;

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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223 is ERC20 {
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    function transferFrom(address from, address to, uint256 value, bytes data) public returns (bool);
    function approve(address spender, uint256 value, bytes data) public returns (bool);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract ERC223Token is ERC223, StandardToken {
    function transfer(address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        super.transfer(to, value);
        require(to.call(data));
        return true;
    }

    function transferFrom(address from, address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        super.transferFrom(from, to, value);
        require(to.call(data));
        return true;
    }

    function approve(address spender, uint256 value, bytes data) public returns (bool) {
        require(spender != address(this));
        super.approve(spender, value);
        require(spender.call(data));
        return true;
    }

    function increaseApproval(address spender, uint addedValue, bytes data) public returns (bool) {
        require(spender != address(this));
        super.increaseApproval(spender, addedValue);
        require(spender.call(data));
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue, bytes data) public returns (bool) {
        require(spender != address(this));
        super.decreaseApproval(spender, subtractedValue);
        require(spender.call(data));
        return true;
    }
}

contract SimpleToken is Pausable, ERC223Token {
    string public constant name = "BLOCK JOY";
    string public constant symbol = "JOY";

    event Buy(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event Sell(address indexed seller, uint256 tokenAmount, uint256 ethAmount);

    function SimpleToken() public {
        owner = msg.sender;
    }

    function sell(uint256 tokenAmount) external {
        require(tokenAmount > 0);
        require(tokenAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
        totalSupply_ = totalSupply_.sub(tokenAmount);
        Transfer(msg.sender, 0x0, tokenAmount);

        uint256 ethAmount = tokenAmount.div(10000);
        uint256 fee = ethAmount.div(1000);
        ethAmount = ethAmount.sub(fee);

        Sell(msg.sender, tokenAmount, ethAmount);

        if (fee > 0) {
            owner.transfer(fee);
        }

        if (ethAmount > 0) {
            msg.sender.transfer(ethAmount);
        }
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= this.balance);
        owner.transfer(amount);
    }

    function() external payable whenNotPaused {
        require(msg.value > 0);

        uint256 tokenAmount = msg.value.mul(10000);
        totalSupply_ = totalSupply_.add(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        Buy(msg.sender, msg.value, tokenAmount);
        Transfer(0x0, msg.sender, tokenAmount);
    }
}
```