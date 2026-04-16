```solidity
pragma solidity ^0.4.24;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MultiSigWallet {
    address public owner1;
    address public owner2;
    uint256 public gasPriceLimit;
    
    uint256 public constant WHOLE_ETHER = 10**18;
    uint256 public constant FRACTION_ETHER = 10**9;
    uint256 public constant DAY_LENGTH = 86400;
    uint256 public constant MAX_DAILY_TOKEN_SOLO_SPEND = 2500000 * FRACTION_ETHER;
    uint256 public constant MAX_DAILY_COSIGN_SEND = 5 * FRACTION_ETHER;
    uint256 public constant COSIGN_MAX_TIME = 300;
    uint256 public constant GAS_PRICE_LIMIT = 200 * 10**9;
    
    mapping(address => uint256) public lastSpendTime;
    mapping(address => uint256) public lastCosignTime;
    
    uint256 public mAmount1;
    uint256 public mAmount2;
    
    constructor() public {
        owner1 = 0xa5a5f62BfA22b1E42A98Ce00131eA658D5E29B37;
        owner2 = 0x9115a6162D6bC3663dC7f4Ea46ad87db6B9CB926;
        gasPriceLimit = GAS_PRICE_LIMIT;
    }
    
    function setGasPriceLimit(uint256 newLimit) public {
        require(msg.sender == owner1 || msg.sender == owner2);
        gasPriceLimit = newLimit;
    }
    
    function spendWithCosign(
        address tokenAddress,
        uint256 wholeAmount,
        uint256 fractionAmount
    ) public returns (bool success) {
        require(tokenAddress != address(0));
        require(wholeAmount <= MAX_DAILY_TOKEN_SOLO_SPEND);
        require(fractionAmount < (WHOLE_ETHER / FRACTION_ETHER));
        require(tx.gasprice <= gasPriceLimit);
        
        resetCosignTimes();
        
        uint256 currentTime = block.timestamp;
        uint256 cosign1 = 0;
        uint256 cosign2 = 0;
        
        if (block.timestamp - lastCosignTime[owner1] < COSIGN_MAX_TIME) {
            mAmount1 = wholeAmount * WHOLE_ETHER + fractionAmount * FRACTION_ETHER;
            cosign1 = 1;
        }
        
        if (block.timestamp - lastCosignTime[owner2] < COSIGN_MAX_TIME) {
            mAmount2 = wholeAmount * FRACTION_ETHER;
            cosign2 = 1;
        }
        
        if (cosign1 == 1 && cosign2 == 1) {
            require((currentTime - lastSpendTime[msg.sender]) > DAY_LENGTH);
            
            if (mAmount1 == mAmount2) {
                IERC20(tokenAddress).transfer(msg.sender, mAmount1);
                cosign1 = 0;
                cosign2 = 0;
                mAmount1 = 0;
                mAmount2 = 0;
                resetSpendTimes();
                return true;
            }
        }
        return false;
    }
    
    function spendSolo(address tokenAddress) public returns (bool success) {
        require(tokenAddress != address(0));
        require(tx.gasprice <= gasPriceLimit);
        require(msg.sender == owner1 || msg.sender == owner2);
        
        uint256 currentTime = block.timestamp;
        require(currentTime - lastSpendTime[msg.sender] > DAY_LENGTH);
        
        IERC20(tokenAddress).transfer(msg.sender, MAX_DAILY_COSIGN_SEND);
        lastSpendTime[msg.sender] = currentTime;
        return true;
    }
    
    function transferWithCosign(
        IERC20 token,
        address recipient,
        uint256 wholeAmount,
        uint256 fractionAmount
    ) public returns (bool success) {
        require(recipient != address(0));
        require(wholeAmount <= MAX_DAILY_TOKEN_SOLO_SPEND);
        
        uint256 currentTime = block.timestamp;
        uint256 cosign1 = 0;
        uint256 cosign2 = 0;
        
        if (block.timestamp - lastCosignTime[owner1] < COSIGN_MAX_TIME) {
            mAmount1 = wholeAmount * WHOLE_ETHER + fractionAmount * FRACTION_ETHER;
            cosign1 = 1;
        }
        
        if (block.timestamp - lastCosignTime[owner2] < COSIGN_MAX_TIME) {
            mAmount2 = wholeAmount * FRACTION_ETHER;
            cosign2 = 1;
        }
        
        if (cosign1 == 1 && cosign2 == 1) {
            require(currentTime - lastSpendTime[msg.sender] > DAY_LENGTH);
            
            if (mAmount1 == mAmount2) {
                uint256 transferAmount = wholeAmount * WHOLE_ETHER + fractionAmount * FRACTION_ETHER;
                token.transfer(recipient, transferAmount);
                cosign1 = 0;
                cosign2 = 0;
                mAmount1 = 0;
                mAmount2 = 0;
                resetSpendTimes();
                return true;
            }
        }
        return false;
    }
    
    function transferDaily(IERC20 token, address recipient) public returns (bool success) {
        require(recipient != address(0));
        require(msg.sender == owner1 || msg.sender == owner2);
        
        uint256 currentTime = block.timestamp;
        require(currentTime - lastSpendTime[msg.sender] > DAY_LENGTH);
        
        token.transfer(recipient, MAX_DAILY_COSIGN_SEND);
        lastSpendTime[msg.sender] = currentTime;
        return true;
    }
    
    function resetSpendTimes() internal {
        lastSpendTime[owner1] = block.timestamp;
        lastSpendTime[owner2] = block.timestamp;
        lastCosignTime[owner1] = 0;
        lastCosignTime[owner2] = 0;
    }
    
    function resetCosignTimes() internal {
        lastCosignTime[owner1] = block.timestamp;
        lastCosignTime[owner2] = block.timestamp;
    }
    
    function() public payable {
    }
}
```