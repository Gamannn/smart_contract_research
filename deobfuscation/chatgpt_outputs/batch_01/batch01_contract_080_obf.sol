pragma solidity 0.4.23;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BYSToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) public frozenAccountByOwner;

    event FrozenAccount(address target, uint256 deadline);

    constructor() public {
        symbol = "BYS";
        name = "Bayesin";
        decimals = 18;
        _totalSupply = 2000000000 * 10 ** uint(decimals);
        owner = 0xC92221388BA9418777454e142d4dA4513bdb81A1;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    modifier afterFrozenDeadline() {
        if (now >= frozenAccountByOwner[msg.sender]) _;
    }

    function managerAccount(address target, uint256 deadline) public isOwner {
        frozenAccountByOwner[target] = deadline;
        emit FrozenAccount(target, deadline);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public afterFrozenDeadline returns (bool success) {
        require(now > frozenAccountByOwner[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public afterFrozenDeadline returns (bool success) {
        require(tokens > 0);
        require(block.timestamp > frozenAccountByOwner[from]);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function fundTransfer(address to, uint256 amount) internal {
        require(amount > 0);
        require(balances[owner] - amount > 0);
        balances[owner] = safeSub(balances[owner], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(owner, to, amount);
    }
}

contract CrowSale is BYSToken {
    mapping(address => uint256) public fundBalance;
    event GoalReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    uint256 public minGoal;
    uint256 public maxGoal;
    uint256 public amountRaised;
    uint256 public tokenAmountRaised;
    uint256 public bonus01;
    uint256 public bonus01Start;
    uint256 public bonus01End;
    uint256 public bonus02;
    uint256 public bonus02Start;
    uint256 public bonus02End;
    uint256 public bonus;
    uint256 public perPrice;
    uint256 public perDeadLine;
    uint256 public perAmountRaised;
    uint256 public perTokenAmount;
    uint256 public perTokenAmountMax;
    bool public fundingGoalReached;
    bool public crowdsaleClosed;
    address public beneficiary;
    uint256 public freeCrawDeadline;

    constructor() public {
        beneficiary = 0xC92221388BA9418777454e142d4dA4513bdb81A1;
        minGoal = 3000 * 1 ether;
        maxGoal = 20000 * 1 ether;
        perPrice = 13000;
        perDeadLine = 1532620800;
        perTokenAmountMax = 26000000 * 10 ** 18;
        bonus01 = 40;
        bonus01Start = safeMul(0, 1 ether);
        bonus01End = safeMul(2000, 1 ether);
        bonus02 = 20;
        bonus02Start = safeMul(2000, 1 ether);
        bonus02End = safeMul(10000, 1 ether);
    }

    function () public payable {
        require(!crowdsaleClosed);
        require(msg.sender != owner);

        if (block.timestamp > freeCrawDeadline) {
            crowdsaleClosed = true;
            revert();
        }

        uint amount = msg.value;
        uint256 returnTokenAmount = 0;

        if (block.timestamp < perDeadLine) {
            if (perTokenAmount >= perTokenAmountMax) {
                revert();
            }
            perAmountRaised = safeAdd(perAmountRaised, amount);
            returnTokenAmount = safeMul(amount, perPrice);
            perTokenAmount = safeAdd(perTokenAmount, returnTokenAmount);
        } else {
            fundBalance[msg.sender] = safeAdd(fundBalance[msg.sender], amount);
            if ((amountRaised >= bonus01Start) && (amountRaised < bonus01End)) {
                bonus = bonus01;
            } else if ((amountRaised >= bonus02Start) && (amountRaised < bonus02End)) {
                bonus = bonus02;
            } else {
                bonus = 0;
            }
            amountRaised = safeAdd(amountRaised, amount);
            returnTokenAmount = safeMul(amount, perPrice);
            returnTokenAmount = safeAdd(returnTokenAmount, safeDiv(safeMul(returnTokenAmount, bonus), 100));
        }

        tokenAmountRaised = safeAdd(tokenAmountRaised, returnTokenAmount);
        fundTransfer(msg.sender, returnTokenAmount);
        emit FundTransfer(msg.sender, amount, true);

        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
        }

        if (amountRaised >= maxGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
        }
    }

    modifier afterDeadline() {
        if ((now >= freeCrawDeadline) || (amountRaised >= maxGoal)) _;
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached && beneficiary != msg.sender) {
            uint amount = fundBalance[msg.sender];
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                fundBalance[msg.sender] = 0;
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (address(this).balance > 0) {
                msg.sender.transfer(address(this).balance);
                emit FundTransfer(beneficiary, address(this).balance, false);
                perAmountRaised = 0;
            }
        }
    }

    function perSaleWithDrawal() public {
        require(beneficiary == msg.sender);
        if (perAmountRaised > 0) {
            msg.sender.transfer(perAmountRaised);
            emit FundTransfer(beneficiary, perAmountRaised, false);
            perAmountRaised = 0;
        }
    }
}