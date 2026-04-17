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

interface ITokenReceiver {
    function tokensReceived(address sender, uint256 amount, address tokenContract, bytes calldata data) external;
}

interface IOracle {
    function getPrice() external view returns (bytes32);
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
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    uint256 public timeBetweenPriceAdjustments;
    uint256 public lastPriceAdjustment;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event gotPEG(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event gotEther(address indexed seller, uint256 tokenAmount, uint256 ethAmount);
    event Inflate(uint256 oldBalance, uint256 inflationAmount);
    event Deflate(uint256 oldBalance, uint256 deflationAmount);
    event Burn(address indexed burner, uint256 amount);
    
    IOracle private oracle;
    
    constructor() payable public {
        name = "Ox3ddbd58c6d244db40d298f073f9877dd504981b7 Stablecoin";
        symbol = "Ox3ddbd58c6d244db40d298f073f9877dd504981b7";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60 * 60;
        
        oracle = IOracle(0x729D19f657BD0614b4985Cf1D82531c67569197B);
        
        totalSupply = getPrice().mul(address(this).balance).div(10**uint(decimals));
        balances[address(this)] = totalSupply;
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
            redeem(amount);
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
        ITokenReceiver(spender).tokensReceived(msg.sender, amount, address(this), data);
        return true;
    }
    
    function() external payable {
        buy();
    }
    
    modifier updatePrice {
        _;
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) {
            adjustPrice();
        }
    }
    
    function timeUntilNextAdjustment() public view returns (uint256 timeRemaining) {
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) return 0;
        return (lastPriceAdjustment + timeBetweenPriceAdjustments) - now;
    }
    
    function buy() public payable updatePrice returns (bool success, uint256 tokenAmount) {
        tokenAmount = msg.value.mul(10**5).div(address(this).balance.div(5));
        balances[address(this)] = balances[address(this)].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        emit gotPEG(msg.sender, msg.value, tokenAmount);
        return (true, tokenAmount);
    }
    
    function redeem(uint256 tokenAmount) public updatePrice returns (bool success, uint256 ethAmount) {
        ethAmount = address(this).balance.mul(tokenAmount.mul(10**5).div(balanceOf(address(this)).add(tokenAmount))).div(10**5);
        balances[address(this)] = balances[address(this)].add(tokenAmount);
        balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
        emit gotEther(msg.sender, tokenAmount, ethAmount);
        msg.sender.transfer(ethAmount);
        return (true, ethAmount);
    }
    
    function getReserves() public view returns (uint256 ethReserve, uint256 tokenReserve) {
        return (address(this).balance, balanceOf(address(this)));
    }
    
    function donate() public payable returns (bool success) {
        return true;
    }
    
    function getPrice() public view returns (uint256 price) {
        bytes32 priceBytes = oracle.getPrice();
        return uint(priceBytes);
    }
    
    function adjustPrice() private returns (uint256 newRate) {
        uint256 targetBalance = getPrice().mul(address(this).balance).div(10**uint(decimals));
        
        if (targetBalance > balances[address(this)]) {
            uint256 inflationAmount = targetBalance.sub(balances[address(this)]).div(10);
            newRate = balances[address(this)].add(inflationAmount);
            emit Inflate(balances[address(this)], inflationAmount);
            balances[address(this)] = newRate;
            totalSupply = totalSupply.add(inflationAmount);
        } else if (targetBalance < balances[address(this)]) {
            uint256 deflationAmount = balances[address(this)].sub(targetBalance).div(10);
            newRate = balances[address(this)].sub(deflationAmount);
            emit Deflate(balances[address(this)], deflationAmount);
            balances[address(this)] = newRate;
            totalSupply = totalSupply.sub(deflationAmount);
        } else {
            newRate = balances[address(this)];
        }
        
        lastPriceAdjustment = now;
    }
    
    function rescueTokens(address tokenAddress, uint256 amount) public onlyOwner returns (bool success) {
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