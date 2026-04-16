pragma solidity ^0.4.13;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Token {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    enum State { INIT, ICO, CLOSED, PAUSE }
    State public currentState;

    uint256 public constant MAX_SUPPLY = 3400000000 * 10 ** 18;
    uint256 public constant WEI_DECIMALS = 10 ** 18;
    uint256 public currentPrice;
    uint256 public totalFunds;
    address public beneficiary;

    event StateChanged(State newState);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);

    modifier inState(State state) {
        require(currentState == state);
        _;
    }

    modifier notClosed() {
        require(currentState != State.CLOSED);
        _;
    }

    function Crowdsale(address _beneficiary) public {
        beneficiary = _beneficiary;
        currentState = State.INIT;
    }

    function () public payable inState(State.ICO) {
        buyTokens();
    }

    function setPrice(uint256 newPrice) public onlyOwner notClosed {
        currentPrice = newPrice;
    }

    function setState(State newState) public onlyOwner {
        require(currentState != State.CLOSED);
        require(
            (currentState == State.INIT && newState == State.ICO) ||
            (currentState == State.ICO && (newState == State.CLOSED || newState == State.PAUSE)) ||
            (currentState == State.PAUSE && newState == State.ICO)
        );

        if (newState == State.CLOSED) {
            finalize();
        }

        currentState = newState;
        StateChanged(newState);
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount > 0 && amount <= this.balance);
        beneficiary.transfer(amount);
        FundsWithdrawn(beneficiary, amount);
    }

    function buyTokens() internal {
        require(msg.value != 0);

        uint256 tokens = msg.value.mul(currentPrice).div(WEI_DECIMALS);
        require(totalSupply.add(tokens) <= MAX_SUPPLY);

        totalSupply = totalSupply.add(tokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);

        Transfer(address(0), msg.sender, tokens);
    }

    function finalize() internal {
        // Finalization logic
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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