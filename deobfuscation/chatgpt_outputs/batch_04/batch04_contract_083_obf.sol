```solidity
pragma solidity ^0.5.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOracle {
    function getPrice() external view returns (bytes32);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
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

contract Stablecoin is IERC20, Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    uint256 public lastPriceAdjustment;
    uint256 public timeBetweenPriceAdjustments;
    IOracle public oracle;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event PriceInflated(uint256 oldSupply, uint256 newSupply);
    event PriceDeflated(uint256 oldSupply, uint256 newSupply);

    constructor() public payable {
        name = "Stablecoin";
        symbol = "STBL";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60 * 60;
        oracle = IOracle(0x729D19f657BD0614b4985Cf1D82531c67569197B);
        _totalSupply = getPrice().mul(balanceOf(address(this))).div(10**uint(decimals));
        _balances[address(this)] = _totalSupply;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0));
        if (recipient == address(this)) {
            burn(amount);
        } else {
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function getPrice() public view returns (uint256) {
        bytes32 price = oracle.getPrice();
        return uint(price);
    }

    function adjustPrice() private returns (uint256 newSupply) {
        uint256 targetSupply = getPrice().mul(balanceOf(address(this))).div(10**uint(decimals));
        if (targetSupply > _balances[address(this)]) {
            uint256 inflation = targetSupply.sub(_balances[address(this)]).div(10);
            newSupply = _balances[address(this)].add(inflation);
            emit PriceInflated(_balances[address(this)], newSupply);
            _balances[address(this)] = newSupply;
            _totalSupply = _totalSupply.add(inflation);
        } else if (targetSupply < _balances[address(this)]) {
            uint256 deflation = _balances[address(this)].sub(targetSupply).div(10);
            newSupply = _balances[address(this)].sub(deflation);
            emit PriceDeflated(_balances[address(this)], newSupply);
            _balances[address(this)] = newSupply;
            _totalSupply = _totalSupply.sub(deflation);
        } else {
            newSupply = _balances[address(this)];
        }
        lastPriceAdjustment = now;
    }

    function () external payable {
        buyTokens();
    }

    modifier priceAdjustment() {
        _;
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) {
            adjustPrice();
        }
    }

    function buyTokens() public payable priceAdjustment returns (bool success, uint256 tokens) {
        tokens = msg.value.mul(getPrice()).div(10**5).div(balanceOf(address(this)));
        _balances[address(this)] = _balances[address(this)].sub(tokens);
        _balances[msg.sender] = _balances[msg.sender].add(tokens);
        emit Transfer(address(this), msg.sender, tokens);
        return (true, tokens);
    }

    function sellTokens(uint256 tokens) public priceAdjustment returns (bool success, uint256 etherAmount) {
        etherAmount = balanceOf(address(this)).mul(tokens.mul(getPrice()).div(10**5).div(balanceOf(address(this)))).div(10**5);
        _balances[address(this)] = _balances[address(this)].add(tokens);
        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        emit Transfer(msg.sender, address(this), tokens);
        msg.sender.transfer(etherAmount);
        return (true, etherAmount);
    }

    function getContractBalance() public view returns (uint256 tokenBalance, uint256 etherBalance) {
        return (balanceOf(address(this)), address(this).balance);
    }

    function fallback() public payable returns (bool) {
        return true;
    }

    function getContractCode() public view returns (bytes memory code) {
        address self = address(this);
        assembly {
            let size := extcodesize(self)
            code := mload(0x40)
            mstore(0x40, add(code, and(add(size, 0x20), not(0x1f))))
            mstore(code, size)
            extcodecopy(self, add(code, 0x20), 0, size)
        }
    }
}
```