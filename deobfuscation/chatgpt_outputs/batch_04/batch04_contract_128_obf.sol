```solidity
pragma solidity ^0.4.19;

contract TokenContract {
    struct TokenData {
        uint256 totalSupply;
        address owner;
        uint256 randomSeed;
        uint256 rewardMultiplier;
        uint256 randomNumber;
        uint256 baseReward;
        uint256 maxSupply;
        uint256 initialSupply;
        uint8 decimals;
        string name;
        string symbol;
    }

    TokenData public tokenData = TokenData(
        0,
        msg.sender,
        0,
        1000,
        0,
        10000000,
        0,
        0,
        18,
        "Token",
        "TKN"
    );

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public nonces;

    modifier onlyOwner() {
        if (msg.sender != tokenData.owner) revert();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        tokenData.owner = newOwner;
    }

    function TokenContract() public {
        tokenData.owner = msg.sender;
        tokenData.initialSupply = 10000000000000000000000000;
        balances[this] = tokenData.initialSupply - balances[tokenData.owner];
    }

    function internalTransfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);

        uint256 previousBalances = balances[from] + balances[to];
        balances[from] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        assert(balances[from] + balances[to] == previousBalances);
    }

    function transfer(address to, uint256 value) external {
        internalTransfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        require(value <= allowances[from][msg.sender]);
        allowances[from][msg.sender] -= value;
        internalTransfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool success) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function withdraw() external onlyOwner {
        tokenData.randomSeed = 0;
    }

    function () external payable {
        if (msg.value == uint256(getIntFunc(3))) {
            tokenData.randomSeed += block.timestamp + uint(msg.sender);
            uint256 blockHash = uint(block.blockhash(block.number - 1));
            uint256 randomValue = uint(sha256(blockHash + tokenData.randomSeed + uint256(getIntFunc(6)))) % 10000000;
            uint256 reward = balances[msg.sender] * 1000 / tokenData.initialSupply;

            if (reward >= 1) {
                if (reward > 255) {
                    reward = 255;
                }
                uint256 rewardAmount = 2 ** reward;
                uint256 maxReward = 50000;
                uint256 minReward = 5000000 - reward;

                if (randomValue < minReward) {
                    uint256 payout = tokenData.baseReward + randomValue * 1000 / tokenData.rewardMultiplier * 100000000000000;
                    internalTransfer(this, msg.sender, payout);
                    nonces[msg.sender]++;
                } else {
                    Transfer(this, msg.sender, 0);
                }
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    bool[] public _bool_constant = [true];
    uint256[] public _integer_constant = [
        1000000000000000000,
        10000000000000000000000000,
        18,
        0,
        100000000000000,
        255,
        1,
        10000000,
        5000000,
        700000000000000,
        5,
        1000,
        2
    ];
    string[] public _string_constant = ["TokenContract"];
}
```