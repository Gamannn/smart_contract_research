```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public newOwner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) pure internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20Token is SafeMath, Ownable {
    string public name;
    string public symbol;
    uint public decimals = 8;
    uint public totalSupply = 10 * 10000 * 10000 * 10 ** uint256(decimals);
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function ERC20Token(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
        balanceOf[this] = totalSupply;
        Transfer(0x0, this, totalSupply);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(address _to, uint _value) public onlyOwner {
        require(balanceOf[this] >= _value);
        balanceOf[this] -= _value;
        balanceOf[_to] += _value;
        Transfer(this, _to, _value);
    }
}

contract BettingGame is SafeMath, Ownable {
    uint256 public minBet = 0.1 ether;
    uint256 public maxBet = 100 ether;
    uint public gameState = 0;
    ERC20Token public tokenContract;

    event Bet(address indexed player, uint amount);

    modifier validBet() {
        require(msg.value >= minBet && msg.value <= maxBet);
        _;
    }

    modifier gameNotRunning() {
        require(gameState == 0);
        _;
    }

    function BettingGame(address _tokenContract) public {
        tokenContract = ERC20Token(_tokenContract);
    }

    function placeBet() public payable validBet gameNotRunning {
        uint betAmount = msg.value;
        uint tokenAmount = safeMul(betAmount, 10000) / 10 ** 10;
        tokenContract.mint(msg.sender, tokenAmount);
        Bet(msg.sender, betAmount);
    }

    function startGame() public onlyOwner {
        gameState = 1;
    }

    function endGame() public onlyOwner {
        gameState = 0;
    }

    function withdraw(uint _amount) public onlyOwner {
        require(this.balance >= _amount);
        msg.sender.transfer(_amount);
    }
}
```