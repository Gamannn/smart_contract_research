```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public candidate;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCandidate() {
        require(msg.sender == candidate);
        _;
    }

    function changeOwner(address _candidate) external onlyOwner {
        candidate = _candidate;
    }

    function confirmOwner() external onlyCandidate {
        owner = candidate;
    }
}

contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint public decimals = 8;
    mapping(address => uint) public balances;
    mapping(address => uint) public whitelist;
    uint public totalSupply = 10 * 10000 * 10000 * 10 ** uint256(decimals);

    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }

    function addToWhitelist(address _addr) public validAddress(_addr) onlyOwner {
        whitelist[_addr] = 1;
    }

    function removeFromWhitelist(address _addr) public validAddress(_addr) onlyOwner {
        whitelist[_addr] = 0;
    }

    function BasicToken(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        balances[this] = totalSupply;
        Transfer(0x0, this, totalSupply);
    }

    function transfer(address _to, uint _value) public validAddress(_to) returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function batchTransfer(address[] _to, uint256[] _value) public returns(bool success) {
        for(uint i = 0; i < _to.length; i++){
            require(transfer(_to[i], _value[i]));
        }
        return true;
    }

    function _mint(address _to, uint _value) private returns (bool success) {
        balances[this] -= _value;
        balances[_to] += _value;
        Transfer(this, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public validAddress(_from) validAddress(_to) returns (bool success) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        require(allowances[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public validAddress(_spender) returns (bool success) {
        require(_value == 0 || allowances[msg.sender][_spender] == 0);
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function () public payable {
    }

    function mint(address _to, uint _value) public validAddress(_to) {
        if(whitelist[msg.sender] != 1) return;
        if(balances[this] == 0) return;
        uint amount = _value;
        if(balances[this] < amount) {
            amount = balances[this];
        }
        require(_mint(_to, amount));
        Mint(_to, amount);
    }

    function withdraw(uint _amount) public onlyOwner {
        require(this.balance >= _amount);
        msg.sender.transfer(_amount);
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint)) public allowances;

    event Mint(address _to, uint _value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Game is ERC20, SafeMath, Ownable {
    uint256 public seed = 0;
    uint public gameState = 0;
    uint private constant GAME_FINISHED = 0;
    uint private constant GAME_PAUSED = 2;
    uint public gameCount = 0;
    uint public minEth = 0.1 ether;
    uint public maxEth = 100 ether;
    uint public commissionRate = 10;
    address public opponent;
    uint public opponentAmount;
    BasicToken public tokenContract;
    address public creator;
    uint public createTime;

    event Bet(address player, uint amount);

    modifier validBet() {
        require(msg.value >= minEth && msg.value <= maxEth);
        _;
    }

    modifier gameRunning() {
        require(gameState == GAME_FINISHED);
        _;
    }

    function Game(address _tokenContract) public validAddress(_tokenContract) {
        tokenContract = BasicToken(_tokenContract);
        creator = msg.sender;
        createTime = now;
    }

    function () public payable {
        bet();
    }

    function setCommissionRate(uint _rate) public onlyOwner {
        require(_rate > 0 && _rate <= 20);
        commissionRate = _rate;
    }

    function setMinEth(uint _min) public onlyOwner {
        require(_min >= 0.01 ether);
        minEth = _min;
    }

    function setMaxEth(uint _max) public onlyOwner {
        require(_max >= 0.1 ether);
        maxEth = _max;
    }

    function setTokenContract(address _token) public onlyOwner {
        tokenContract = BasicToken(_token);
    }

    function bet() public payable gameRunning validBet {
        uint betAmount = msg.value;
        uint commission = 0;
        uint amount = 0;
        address winner;
        address loser;
        uint opponentBet = 0;
        uint winAmount;
        uint tokenAmount = 0;

        seed = add(seed, betAmount);

        if (opponent == address(0)) {
            opponent = msg.sender;
            opponentAmount = betAmount;
        } else {
            winner = determineWinner(opponent, msg.sender, opponentAmount, betAmount);
            if(winner == msg.sender) {
                loser = opponent;
                amount = opponentAmount;
                opponent = address(0);
                opponentAmount = 0;
                winAmount = amount;
            } else {
                winner = opponent;
                loser = msg.sender;
                opponentBet = betAmount;
                winAmount = betAmount * commissionRate / 100;
            }
            tokenAmount = opponentBet * 10000 / 10 ** 10;
            tokenContract.mint(winner, tokenAmount);
            gameCount = add(gameCount, 1);
            commission = add(opponentAmount, betAmount);
            winAmount = sub(commission, winAmount);
            require(_mint(winner, winAmount));
            resetGame();
        }
    }

    function resetGame() private {
        opponent = address(0);
        opponentAmount = 0;
    }

    function determineWinner(address player1, address player2, uint bet1, uint bet2) private returns(address) {
        uint total = add(bet1, bet2);
        uint probability = bet1 * 10 ** 2 / total;
        uint random = random(100);
        if (random <= probability) {
            return player1;
        } else {
            return player2;
        }
    }

    function withdraw(uint _amount) public onlyOwner {
        uint available = 0;
        if (opponent != address(0)) {
            available = this.balance - opponentAmount;
        } else {
            available = this.balance;
        }
        require(available >= _amount);
        msg.sender.transfer(_amount);
    }

    function pauseGame() public onlyOwner {
        gameState = GAME_PAUSED;
    }

    function resumeGame() public onlyOwner {
        gameState = GAME_FINISHED;
    }

    function _mint(address _to, uint _value) private returns (bool success) {
        require(this.balance >= _value);
        _to.transfer(_value);
        Transfer(this, _to, _value);
        return true;
    }

    function random(uint256 max) private view returns (uint256) {
        return uint256(keccak256(block.timestamp, block.difficulty, seed)) % max;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowances[_owner][_spender];
    }
}
```