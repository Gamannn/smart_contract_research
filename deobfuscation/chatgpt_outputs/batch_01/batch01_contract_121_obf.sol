pragma solidity ^0.4.21;

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

contract Token {
    function transfer(address to, uint256 value) public;
    function deposit() payable public;
    function balanceOf() public view returns(uint256);
}

contract Bank {
    function withdraw(uint256 amount, address to) public;
    function deposit() payable public;
    function transferTo(uint256 amount) public;
    function balance() public view returns(uint256);
}

contract ERC20 {
    function totalSupply() constant public returns (uint supply);
    function balanceOf(address who) constant public returns (uint value);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function allowance(address owner, address spender) constant public returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract EOSBetStake is ERC20, Bank {
    using SafeMath for uint256;

    mapping(address => bool) public authorized;
    mapping(address => uint256) public lastTransaction;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    event FundBankroll(address indexed from, uint256 value, uint256 tokens);
    event CashOut(address indexed to, uint256 value, uint256 tokens);
    event FailedSend(address indexed to, uint256 value);

    modifier onlyAuthorized(address account) {
        require(authorized[account]);
        _;
    }

    function EOSBetStake(address admin1, address admin2) public payable {
        require(msg.value > 0);
        state.owner = msg.sender;
        uint256 tokens = msg.value.mul(100);
        balances[msg.sender] = tokens;
        state.totalSupply = tokens;
        emit Transfer(0x0, msg.sender, tokens);
        authorized[admin1] = true;
        authorized[admin2] = true;
        state.admin1 = admin1;
        state.admin2 = admin2;
        state.lockTime = 6 hours;
        state.maxBet = 500 ether;
    }

    function balanceOf(address account) view public returns(uint256) {
        return lastTransaction[account];
    }

    function balance() view public returns(uint256) {
        return SafeMath.sub(address(this).balance, state.reserved);
    }

    function withdraw(uint256 amount, address to) public onlyAuthorized(msg.sender) {
        if (!to.send(amount)) {
            emit FailedSend(to, amount);
            if (!state.owner.send(amount)) {
                emit FailedSend(state.owner, amount);
            }
        }
    }

    function deposit() payable public onlyAuthorized(msg.sender) {}

    function transferTo(uint256 amount) public onlyAuthorized(msg.sender) {
        Token(msg.sender).deposit.value(amount)();
    }

    function () public payable {
        uint256 availableBalance = SafeMath.sub(balance(), msg.value);
        uint256 maxBet = state.maxBet;
        require(availableBalance < maxBet && msg.value != 0);
        uint256 totalSupply = state.totalSupply;
        uint256 tokens;
        bool overMaxBet;
        uint256 refund;
        uint256 newTokens;

        if (SafeMath.add(availableBalance, msg.value) > maxBet) {
            overMaxBet = true;
            tokens = SafeMath.sub(maxBet, availableBalance);
            refund = SafeMath.sub(msg.value, tokens);
        } else {
            tokens = msg.value;
        }

        if (totalSupply != 0) {
            newTokens = SafeMath.mul(tokens, totalSupply).div(availableBalance);
        } else {
            newTokens = SafeMath.mul(tokens, 100);
        }

        state.totalSupply = SafeMath.add(totalSupply, newTokens);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], newTokens);
        lastTransaction[msg.sender] = block.timestamp;

        if (overMaxBet) {
            msg.sender.transfer(refund);
        }

        emit FundBankroll(msg.sender, tokens, newTokens);
        emit Transfer(0x0, msg.sender, newTokens);
    }

    function cashOut(uint256 tokens) public {
        uint256 balance = balances[msg.sender];
        require(tokens <= balance && lastTransaction[msg.sender] + state.lockTime <= block.timestamp && tokens > 0);
        uint256 availableBalance = balance();
        uint256 totalSupply = state.totalSupply;
        uint256 ethAmount = SafeMath.mul(tokens, availableBalance).div(totalSupply);
        uint256 fee = ethAmount.div(100);
        uint256 payout = SafeMath.sub(ethAmount, fee);

        state.totalSupply = SafeMath.sub(totalSupply, tokens);
        balances[msg.sender] = SafeMath.sub(balance, tokens);
        state.reserved = SafeMath.add(state.reserved, fee);

        msg.sender.transfer(payout);
        emit CashOut(msg.sender, payout, tokens);
        emit Transfer(msg.sender, 0x0, tokens);
    }

    function cashOutAll() public {
        cashOut(balances[msg.sender]);
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == state.owner);
        state.owner = newOwner;
    }

    function setLockTime(uint256 lockTime) public {
        require(msg.sender == state.owner && lockTime <= 6048000);
        state.lockTime = lockTime;
    }

    function setMaxBet(uint256 maxBet) public {
        require(msg.sender == state.owner);
        state.maxBet = maxBet;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == state.owner);
        Token(state.admin1).transfer(newOwner);
        Token(state.admin2).transfer(newOwner);
        uint256 reserved = state.reserved;
        state.reserved = 0;
        newOwner.transfer(reserved);
    }

    function transferTokens(address to, uint256 value) public {
        require(msg.sender == state.owner);
        ERC20(to).transfer(msg.sender, value);
    }

    function totalSupply() constant public returns(uint) {
        return state.totalSupply;
    }

    function balanceOf(address account) constant public returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value && lastTransaction[msg.sender] + state.lockTime <= block.timestamp && to != address(this) && to != address(0));
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(allowed[from][msg.sender] >= value && balances[from] >= value && lastTransaction[from] + state.lockTime <= block.timestamp && to != address(this) && to != address(0));
        balances[to] = SafeMath.add(balances[to], value);
        balances[from] = SafeMath.sub(balances[from], value);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant public returns(uint) {
        return allowed[owner][spender];
    }

    struct State {
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        address admin1;
        address admin2;
        uint256 reserved;
        uint256 lockTime;
        uint256 maxBet;
        address owner;
        uint256 reserved1;
        uint256 reserved2;
    }

    State state = State(0, 18, "EOSBETST", "EOSBet Stake Tokens", address(0), address(0), 0, 0, 0, address(0), 0, 0);
}