```solidity
pragma solidity ^0.4.19;

contract Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function internalTransfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);

        uint256 previousBalances = balances[from] + balances[to];
        balances[from] -= value;
        balances[to] += value;
        assert(balances[from] + balances[to] == previousBalances);

        Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        internalTransfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowances[from][msg.sender]);
        allowances[from][msg.sender] -= value;
        internalTransfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract AirdropToken is Token {
    mapping(address => uint32) public airdropCounts;
    event Airdrop(address indexed to, uint32 indexed count, uint256 amount);

    function claimAirdrop() public payable {
        require(now >= getIntFunc(3) && now <= getIntFunc(2));
        require(msg.value == 0);

        if (airdropCounts[msg.sender] >= getIntFunc(12)) {
            revert();
        }

        internalTransfer(getAddressFunc(0), msg.sender, getIntFunc(11));
        airdropCounts[msg.sender] += 1;
        Airdrop(msg.sender, airdropCounts[msg.sender], getIntFunc(11));
    }
}

contract ICOContract is Token {
    event ICO(address indexed buyer, uint256 indexed ethAmount, uint256 tokenAmount);
    event Withdraw(address indexed from, address indexed to, uint256 value);

    function buyTokens() public payable {
        require(now >= getIntFunc(4) && now <= getIntFunc(5));

        uint256 tokenAmount = (msg.value * getIntFunc(9) * getIntFunc(10)) / (1 ether / 1 wei);
        require(tokenAmount > 0 && balances[getAddressFunc(1)] >= tokenAmount);

        internalTransfer(getAddressFunc(1), msg.sender, tokenAmount);
        ICO(msg.sender, msg.value, tokenAmount);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        getAddressFunc(2).transfer(balance);
        Withdraw(msg.sender, getAddressFunc(2), balance);
    }
}

contract FundOfFunds is Token, AirdropToken, ICOContract {
    function FundOfFunds() public {
        balances[getAddressFunc(1)] = getIntFunc(8);
        totalSupply = getIntFunc(8);
        decimals = uint8(getIntFunc(1));
        name = getStrFunc(1);
        symbol = getStrFunc(0);
    }

    struct Config {
        address airdropSender;
        address icoSender;
        uint256 icoStartTime;
        uint256 icoEndTime;
        uint256 icoRatio;
        uint32 airdropLimit;
        address withdrawAddress;
        uint256 airdropAmount;
        uint256 totalSupply;
        uint256 decimals;
        uint256 airdropStartTime;
        uint256 airdropEndTime;
        string name;
        string symbol;
    }

    Config config = Config(
        address(0),
        address(0),
        getIntFunc(4),
        getIntFunc(5),
        getIntFunc(9),
        uint32(getIntFunc(12)),
        getAddressFunc(2),
        getIntFunc(11),
        getIntFunc(8),
        getIntFunc(1),
        getIntFunc(3),
        getIntFunc(2),
        getStrFunc(1),
        getStrFunc(0)
    );

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    function getAddressFunc(uint256 index) internal view returns (address) {
        return _address_constant[index];
    }

    uint256[] public _integer_constant = [
        1, 18, 1837656000, 1522029600, 1434, 1000000000000000000, 21000000000000000000000000000, 1522036800, 1585188000, 3000, 0, 20000000000000000000, 10
    ];
    string[] public _string_constant = ["FOF", "FundofFunds"];
    address[] public _address_constant = [0x0, 0x0, 0x0];
}
```