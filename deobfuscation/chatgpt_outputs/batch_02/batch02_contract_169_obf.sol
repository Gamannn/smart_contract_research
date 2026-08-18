pragma solidity ^0.4.18;

contract FutereumMiniature {
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public reservedFees = 0;
    uint256 public submittedFeesPaid = 0;
    uint256 public penaltyPaid = 0;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MiningStart(uint256 startTime, uint256 endTime, uint256 swapTime);
    event MiningExtended(uint256 newEndTime, uint256 newSwapTime, uint256 newSwapEndTime);

    struct Scalar2Vector {
        address foundation;
        uint256 tierValue;
        bool extended;
        bool payRate;
        uint256 swapTime;
        uint256 endTime;
        uint256 swapEndTime;
        uint256 swapEndTimeExtended;
        uint256 penaltysPaid;
    }
    
    Scalar2Vector s2c;

    function FutereumMiniature() public {
        s2c.foundation = 0x448468d5591C724f5310027B859135d5F6434286;
        s2c.tierValue = 0;
        s2c.extended = false;
        s2c.payRate = false;
        s2c.swapTime = now;
        s2c.endTime = now + 8 hours;
        s2c.swapEndTime = s2c.endTime + 2 hours;
        s2c.swapEndTimeExtended = s2c.swapEndTime + 2 hours;
        s2c.penaltysPaid = 0;
        s2c.tierValue = 0;
        MiningStart(now, s2c.endTime, s2c.swapTime);
    }

    function startMining() public {
        require(s2c.extended && now >= s2c.endTime);
        reservedFees = this.balance * s2c.tierValue / 1000;
        distributeFees();
        resetFees();
    }

    function distributeFees() internal {
        address foundation = 0x448468d5591C724f5310027B859135d5F6434286;
        address foundation2 = 0xb69a63279319197adca53b9853469d3aac586a4c;
        address foundation3 = 0xE252765E4A71e3170b2215cf63C16E7553ec26bD;
        uint256 reserved = reservedFees / 2;
        foundation.transfer(reserved);
        reserved = reservedFees / 4;
        foundation2.transfer(reserved);
        foundation3.transfer(reserved);
    }

    function resetFees() internal {
        s2c.payRate = false;
        s2c.extended = false;
        s2c.tierValue = 0;
        s2c.penaltysPaid = 0;
        reservedFees = 0;
        submittedFeesPaid = 0;
        penaltyPaid = 0;
        totalSupply = 0;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value && allowed[from][msg.sender] >= value);
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    address payable[] public _address_constant = [0x448468d5591C724f5310027B859135d5F6434286, 0xE252765E4A71e3170b2215cf63C16E7553ec26bD];
    bool[] public _bool_constant = [false, true];
    string[] public _string_constant = ["Futereum Miniature", "Ox7c347819fb6b2a3397c574472b70447fbd7e3433"];
    uint256[] public _integer_constant = [5, 10000, 13, 1989552533017940000, 8, 41506715761945900000, 21, 18, 114, 3, 1, 256, 55, 14840049095279200000, 14400, 2000, 9840049095279210000, 28800, 1000000000000000000, 2, 10, 3735007078472480000, 1042, 41, 740000, 89, 30840049095279200000, 4, 21840049095279200000, 1530, 0, 50006715761945500000, 877192982456140000, 7200, 34, 6411477666707780000];
}
