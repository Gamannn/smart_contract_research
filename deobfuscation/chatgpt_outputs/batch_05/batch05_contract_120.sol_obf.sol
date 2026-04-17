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

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC223 {
    function transfer(address to, uint256 value, bytes calldata data) external;
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

interface MedianiserInterface {
    function peek() external view returns (bytes32, bool);
}

contract Stablecoin is ERC20, Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public lastPriceAdjustment;
    uint256 public timeBetweenPriceAdjustments;
    MedianiserInterface public medianiser;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event GotPEG(address indexed from, uint256 value, uint256 amount);
    event GotEther(address indexed from, uint256 value, uint256 amount);
    event Inflate(uint256 oldSupply, uint256 newSupply);
    event Deflate(uint256 oldSupply, uint256 newSupply);
    event NoAdjustment();
    event FailedAdjustment();

    constructor() public payable {
        name = "Stablecoin";
        symbol = "STBL";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60 * 60; // 1 hour
        medianiser = MedianiserInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B);
        (uint256 price, bool valid) = getPrice();
        require(valid);
        totalSupply = price.mul(10**uint(decimals)).div(10**5);
        balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0));
        if (recipient == address(this)) {
            burn(amount);
        } else {
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[recipient] = balances[recipient].add(amount);
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        totalSupply = totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        balances[sender] = balances[sender].sub(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value, bytes memory data) public returns (bool) {
        allowed[msg.sender][to] = value;
        emit Approval(msg.sender, to, value);
        ERC223(to).transfer(msg.sender, value, data);
        return true;
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

    function timeUntilNextAdjustment() public view returns (uint256) {
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) {
            return 0;
        } else {
            return lastPriceAdjustment + timeBetweenPriceAdjustments - now;
        }
    }

    function buyTokens() public payable priceAdjustment returns (bool, uint256) {
        uint256 amount = msg.value.mul(10**5).div(address(this).balance);
        balances[address(this)] = balances[address(this)].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit GotPEG(msg.sender, msg.value, amount);
        emit Transfer(address(this), msg.sender, amount);
        return (true, amount);
    }

    function sellTokens(uint256 amount) public priceAdjustment returns (bool, uint256) {
        uint256 etherAmount = address(this).balance.mul(amount).div(totalSupply);
        balances[address(this)] = balances[address(this)].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit GotEther(msg.sender, amount, etherAmount);
        emit Transfer(msg.sender, address(this), amount);
        msg.sender.transfer(etherAmount);
        return (true, etherAmount);
    }

    function getPrice() public view returns (uint256, bool) {
        bytes32 price;
        bool valid;
        (price, valid) = medianiser.peek();
        return (uint(price), valid);
    }

    function adjustPrice() private returns (uint256) {
        uint256 price;
        bool valid;
        (price, valid) = getPrice();
        if (!valid) {
            emit FailedAdjustment();
            return balances[address(this)];
        }
        price = price.mul(10**uint(decimals)).div(10**5);
        if (price > balances[address(this)]) {
            uint256 increase = price.sub(balances[address(this)]).div(10);
            balances[address(this)] = balances[address(this)].add(increase);
            emit Inflate(balances[address(this)], increase);
            emit Transfer(address(0), address(this), increase);
            totalSupply = totalSupply.add(increase);
        } else if (price < balances[address(this)]) {
            uint256 decrease = balances[address(this)].sub(price).div(10);
            balances[address(this)] = balances[address(this)].sub(decrease);
            emit Deflate(balances[address(this)], decrease);
            emit Transfer(address(this), address(0), decrease);
            totalSupply = totalSupply.sub(decrease);
        } else {
            emit NoAdjustment();
        }
        lastPriceAdjustment = now;
    }

    function withdrawEther(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
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