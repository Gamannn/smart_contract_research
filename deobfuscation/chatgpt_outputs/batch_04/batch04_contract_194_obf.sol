pragma solidity ^0.5.0;

contract SimpleToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private balances;
    uint256 private totalSupply;
    uint256 private rate = 0.006 ether;

    function getContractName() public pure returns (string memory) {
        return "SimpleToken";
    }

    function getSymbol() public pure returns (string memory) {
        return "STK";
    }

    function getDecimals() public pure returns (uint8) {
        return 18;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) payable public {
        require(msg.value >= rate * amount, "Insufficient Ether sent");
        totalSupply += amount;
        balances[msg.sender] += amount;
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        return true;
    }

    bool[] public boolConstants = [true];
    uint256[] public integerConstants = [18, 6000000000000000];

    function getBoolConstant(uint256 index) internal view returns (bool) {
        return boolConstants[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }
}