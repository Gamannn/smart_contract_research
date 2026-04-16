```solidity
pragma solidity ^0.4.24;

contract TokenInterface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract MultiSigWallet {
    address constant owner1 = 0x16be647b17654b3d2b77175d9bf7f1bee5fe099e;
    address constant owner2 = 0x3e86940bbb1fa0975f912c55df6e42e9672520bd;
    uint256 public gasPriceLimit = 200 * 10**9;
    uint256 public maxDailySpend = 2500000 * 10**18;
    uint256 public lastExecutionTime;
    mapping(address => uint256) public lastSpendTime;
    mapping(address => uint256) public dailySpend;

    function setGasPriceLimit(uint256 _gasPriceLimit) public {
        require(msg.sender == owner1 || msg.sender == owner2);
        gasPriceLimit = _gasPriceLimit;
    }

    function executeTransaction(address _tokenAddress, uint256 _amount, uint256 _fee) public returns (bool) {
        require(_tokenAddress != address(0));
        require(_amount <= maxDailySpend);
        require(tx.gasprice <= gasPriceLimit);

        uint256 currentTime = block.timestamp;
        uint256 totalSpend = _amount + _fee;

        if (currentTime - lastSpendTime[owner1] < 1 days) {
            dailySpend[owner1] += totalSpend;
        } else {
            dailySpend[owner1] = totalSpend;
        }

        if (currentTime - lastSpendTime[owner2] < 1 days) {
            dailySpend[owner2] += totalSpend;
        } else {
            dailySpend[owner2] = totalSpend;
        }

        require(dailySpend[owner1] <= maxDailySpend && dailySpend[owner2] <= maxDailySpend);

        TokenInterface token = TokenInterface(_tokenAddress);
        require(token.transfer(msg.sender, _amount));

        lastSpendTime[msg.sender] = currentTime;
        return true;
    }

    function executeDailyTransaction(address _tokenAddress, uint256 _amount) public returns (bool) {
        require(_tokenAddress != address(0));
        require(msg.sender == owner1 || msg.sender == owner2);

        uint256 currentTime = block.timestamp;
        require(currentTime - lastSpendTime[msg.sender] > 1 days);

        TokenInterface token = TokenInterface(_tokenAddress);
        require(token.transfer(msg.sender, _amount));

        lastSpendTime[msg.sender] = currentTime;
        return true;
    }

    function resetDailySpend() internal {
        lastSpendTime[owner1] = block.timestamp;
        lastSpendTime[owner2] = block.timestamp;
        dailySpend[owner1] = 0;
        dailySpend[owner2] = 0;
    }

    function () public payable {}
}
```