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
    function balanceOf(address account) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata data) external;
}

interface MedianiserInterface {
    function peek() external view returns (bytes32, bool);
}

contract Ownable {
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
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
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    uint256 public lastPriceAdjustment;
    uint256 public timeBetweenPriceAdjustments;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    MedianiserInterface public medianiser;
    
    event gotPEG(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event gotEther(address indexed seller, uint256 tokenAmount, uint256 ethAmount);
    event Inflate(uint256 oldSupply, uint256 increase);
    event Deflate(uint256 oldSupply, uint256 decrease);
    event NoAdjustment();
    event FailedAdjustment();
    event Burn(address indexed burner, uint256 amount);
    
    constructor() payable public {
        name = "Stablecoin";
        symbol = "STBL";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60 * 60;
        
        medianiser = MedianiserInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B);
        
        (uint256 price, bool isValid) = getPrice();
        require(isValid);
        
        totalSupply = price.mul(address(this).balance).div(10**uint(decimals));
        balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) public returns (bool success) {
        require(to != address(0));
        
        if (to == address(this)) {
            sell(amount);
        } else {
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[to] = balances[to].add(amount);
            emit Transfer(msg.sender, to, amount);
        }
        return true;
    }
    
    function burn(uint256 amount) public returns (bool success) {
        totalSupply = totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Burn(msg.sender, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        balances[from] = balances[from].sub(amount);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowances[owner][spender];
    }
    
    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool success) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        TokenRecipient(spender).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }
    
    function() external payable {
        buy();
    }
    
    modifier adjustPriceAfter {
        _;
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) {
            adjustPrice();
        }
    }
    
    function timeUntilNextAdjustment() public view returns (uint256 timeRemaining) {
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) {
            return 0;
        } else {
            return (lastPriceAdjustment + timeBetweenPriceAdjustments).sub(now);
        }
    }
    
    function buy() public payable adjustPriceAfter returns (bool success, uint256 tokenAmount) {
        tokenAmount = msg.value.mul(10**5).div(address(this).balance).mul(balances[address(this)]).div(10**5);
        balances[address(this)] = balances[address(this)].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        emit gotPEG(msg.sender, msg.value, tokenAmount);
        emit Transfer(address(this), msg.sender, tokenAmount);
        return (true, tokenAmount);
    }
    
    function sell(uint256 tokenAmount) public adjustPriceAfter returns (bool success, uint256 ethAmount) {
        ethAmount = address(this).balance.mul(tokenAmount.mul(10**5).div(balanceOf(address(this)).add(tokenAmount))).div(10**5);
        balances[address(this)] = balances[address(this)].add(tokenAmount);
        balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
        emit gotEther(msg.sender, tokenAmount, ethAmount);
        emit Transfer(msg.sender, address(this), tokenAmount);
        msg.sender.transfer(ethAmount);
        return (true, ethAmount);
    }
    
    function getReserves() public view returns (uint256 ethReserve, uint256 tokenReserve) {
        return (address(this).balance, balanceOf(address(this)));
    }
    
    function donate() public payable returns (bool success) {
        return true;
    }
    
    function getPrice() public view returns (uint256 price, bool isValid) {
        bytes32 priceBytes;
        (priceBytes, isValid) = medianiser.peek();
        return (uint(priceBytes), isValid);
    }
    
    function adjustPrice() private returns (uint256 newTokenReserve) {
        (uint256 price, bool isValid) = getPrice();
        
        if (!isValid) {
            newTokenReserve = balances[address(this)];
            lastPriceAdjustment = now;
            emit FailedAdjustment();
            return newTokenReserve;
        }
        
        price = price.mul(address(this).balance).div(10**uint(decimals));
        
        if (price > balances[address(this)]) {
            uint256 increase = price.sub(balances[address(this)]).div(10);
            newTokenReserve = balances[address(this)].add(increase);
            emit Inflate(balances[address(this)], increase);
            emit Transfer(address(0), address(this), increase);
            balances[address(this)] = newTokenReserve;
            totalSupply = totalSupply.add(increase);
        } else if (price < balances[address(this)]) {
            uint256 decrease = balances[address(this)].sub(price).div(10);
            newTokenReserve = balances[address(this)].sub(decrease);
            emit Deflate(balances[address(this)], decrease);
            emit Transfer(address(this), address(0), decrease);
            balances[address(this)] = newTokenReserve;
            totalSupply = totalSupply.sub(decrease);
        } else {
            newTokenReserve = balances[address(this)];
            emit NoAdjustment();
        }
        
        lastPriceAdjustment = now;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner, amount);
    }
    
    function getContractCode() public view returns (bytes memory contractCode) {
        address contractAddress = address(this);
        assembly {
            let size := extcodesize(contractAddress)
            contractCode := mload(0x40)
            mstore(0x40, add(contractCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(contractCode, size)
            extcodecopy(contractAddress, add(contractCode, 0x20), 0, size)
        }
    }
}
```