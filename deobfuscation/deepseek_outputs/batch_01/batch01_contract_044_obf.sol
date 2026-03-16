pragma solidity ^0.6.6;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IUniswapFactory {
    function getExchange(IERC20 token) external view returns (UniswapExchangeInterface exchange);
}

interface UniswapExchangeInterface {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256 tokens_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256 eth_bought);
}

interface ILiquidityPool {
    event Withdraw(address indexed account, uint amount, uint writeAmount);
    event Provide(address indexed account, uint amount, uint writeAmount);
    function totalBalance() external view returns (uint amount);
    function lock(uint amount) external;
    function unlock(uint amount) external;
    function send(address payable account, uint amount) external;
}

interface IERCLiquidityPool is ILiquidityPool {
    function token() external view returns(IERC20);
}

interface ERC20Incorrect {
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

interface SpreadLock {
    function highSpreadLockEnabled() external returns (bool);
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract HegicETHPool is ILiquidityPool, Ownable, ERC20("Hegic ETH LP Token", "writeETH") {
    using SafeMath for uint256;

    uint256 public lockedAmount;

    receive() external payable {}

    function availableBalance() public view returns (uint balance) {
        balance = totalBalance().sub(lockedAmount);
    }

    function totalBalance() public override view returns (uint balance) {
        balance = address(this).balance;
    }

    function provide(uint minMint) public payable returns (uint mint) {
        mint = provide();
        require(mint >= minMint, "Pool: Mint limit is too large");
    }

    function provide() public payable returns (uint mint) {
        require(!SpreadLock(owner()).highSpreadLockEnabled(), "Pool: Locked");
        if (totalSupply().mul(totalBalance()) == 0)
            mint = msg.value.mul(1000);
        else
            mint = msg.value.mul(totalSupply()).div(totalBalance().sub(msg.value));
        require(mint > 0, "Pool: Amount is too small");
        emit Provide(msg.sender, msg.value, mint);
        _mint(msg.sender, mint);
    }

    function withdraw(uint amount, uint maxBurn) public returns (uint burn) {
        burn = withdraw(amount);
        require(burn <= maxBurn, "Pool: Burn limit is too small");
    }

    function withdraw(uint amount) public returns (uint burn) {
        require(amount <= availableBalance(), "Pool: Insufficient unlocked funds");
        burn = amount.mul(totalSupply()).div(totalBalance());
        require(burn <= balanceOf(msg.sender), "Pool: Amount is too large");
        require(burn > 0, "Pool: Amount is too small");
        _burn(msg.sender, burn);
        emit Withdraw(msg.sender, amount, burn);
        msg.sender.transfer(amount);
    }

    function shareOf(address user) public view returns (uint share) {
        if (totalBalance() > 0)
            share = totalBalance()
                .mul(balanceOf(user))
                .div(totalSupply());
    }

    function lock(uint amount) public override onlyOwner {
        require(
            lockedAmount.add(amount).mul(10).div(totalBalance()) < 8,
            "Pool: Insufficient unlocked funds"
        );
        lockedAmount = lockedAmount.add(amount);
    }

    function unlock(uint amount) public override onlyOwner {
        require(lockedAmount >= amount, "Pool: Insufficient locked funds");
        lockedAmount = lockedAmount.sub(amount);
    }

    function send(address payable to, uint amount) public override onlyOwner {
        require(lockedAmount >= amount, "Pool: Insufficient locked funds");
        lockedAmount -= amount;
        to.transfer(amount);
    }
}

contract HegicERCPool is IERCLiquidityPool, Ownable, ERC20("Hegic DAI LP Token", "writeDAI") {
    using SafeMath for uint256;

    IERC20 public override token;
    uint256 public lockedAmount;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function availableBalance() public view returns (uint balance) {
        balance = totalBalance().sub(lockedAmount);
    }

    function totalBalance() public override view returns (uint balance) {
        balance = token.balanceOf(address(this));
    }

    function provide(uint amount, uint minMint) public returns (uint mint) {
        mint = provide(amount);
        require(mint >= minMint, "Pool: Mint limit is too large");
    }

    function provide(uint amount) public returns (uint mint) {
        require(!SpreadLock(owner()).highSpreadLockEnabled(), "Pool: Locked");
        if (totalSupply().mul(totalBalance()) == 0)
            mint = amount.mul(1000);
        else
            mint = amount.mul(totalSupply()).div(totalBalance());
        require(mint > 0, "Pool: Amount is too small");
        emit Provide(msg.sender, amount, mint);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Insufficient funds"
        );
        _mint(msg.sender, mint);
    }

    function withdraw(uint amount, uint maxBurn) public returns (uint burn) {
        burn = withdraw(amount);
        require(burn <= maxBurn, "Pool: Burn limit is too small");
    }

    function withdraw(uint amount) public returns (uint burn) {
        require(amount <= availableBalance(), "Pool: Insufficient unlocked funds");
        burn = amount.mul(totalSupply()).div(totalBalance());
        require(burn <= balanceOf(msg.sender), "Pool: Amount is too large");
        require(burn > 0, "Pool: Amount is too small");
        _burn(msg.sender, burn);
        emit Withdraw(msg.sender, amount, burn);
        require(
            token.transfer(msg.sender, amount),
            "Insufficient funds"
        );
    }

    function shareOf(address user) public view returns (uint share) {
        if (totalBalance() > 0)
            share = totalBalance()
                .mul(balanceOf(user))
                .div(totalSupply());
    }

    function lock(uint amount) public override onlyOwner {
        require(
            lockedAmount.add(amount).mul(10).div(totalBalance()) < 8,
            "Pool: Insufficient unlocked funds"
        );
        lockedAmount = lockedAmount.add(amount);
    }

    function unlock(uint amount) public override onlyOwner {
        require(lockedAmount >= amount, "Pool: Insufficient locked funds");
        lockedAmount = lockedAmount.sub(amount);
    }

    function send(address payable to, uint amount) public override onlyOwner {
        require(lockedAmount >= amount, "Pool: Insufficient locked funds");
        lockedAmount -= amount;
        require(
            token.transfer(to, amount),
            "Insufficient funds"
        );
    }
}

abstract contract HegicOptions is Ownable, SpreadLock {
    using SafeMath for uint;

    Option[] public options;
    AggregatorInterface public priceProvider;
    IUniswapFactory public exchanges;
    IERC20 token;
    ILiquidityPool public pool;
    OptionType private optionType;

    uint256 public activationTime = 15 minutes;
    uint256 public priceDecimals = 1e8;
    uint256 public maxSpread = 95;
    uint256 public impliedVolRate = 20000;
    bool public highSpreadLockEnabled = false;

    constructor(IERC20 DAI, AggregatorInterface pp, IUniswapFactory ex, OptionType t) public {
        token = DAI;
        priceProvider = pp;
        exchanges = ex;
        optionType = t;
    }

    function setImpliedVolRate(uint value) public onlyOwner {
        require(value >= 10000, "ImpliedVolRate limit is too small");
        impliedVolRate = value;
    }

    function setMaxSpread(uint value) public onlyOwner {
        require(value <= 95, "Spread limit is too large");
        maxSpread = value;
    }

    event Create(uint indexed id, address indexed account, uint fee, uint premium);
    event Exercise(uint indexed id, uint exchangeAmount);
    event Expire(uint indexed id);

    enum State { Active, Exercised, Expired }
    enum OptionType { Put, Call }

    struct Option {
        State state;
        address payable holder;
        uint strikeAmount;
        uint amount;
        uint expiration;
        uint activation;
    }

    function getHegicFee(uint amount) internal pure returns (uint fee) {
        fee = amount / 100;
    }

    function getPeriodFee(uint amount, uint period, uint strike, uint currentPrice) internal view returns (uint fee) {
        fee = amount
            .mul(sqrt(period / 10))
            .mul(impliedVolRate)
            .mul(strike)
            .div(currentPrice)
            .div(1e8);
    }

    function getSlippageFee(uint amount) internal pure returns (uint