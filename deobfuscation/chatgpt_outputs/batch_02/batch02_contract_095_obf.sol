pragma solidity ^0.4.24;

contract DunatonMetacurrency {
    uint256 public totalSupply;
    uint256 public tokenPerEth;
    address public owner;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner = msg.sender;
        totalSupply = 5800000 * 1 ether;
        balances[owner] = totalSupply;
        emit Transfer(address(this), owner, totalSupply);
    }

    function transfer(address to, uint256 value, bytes data) public {
        require(balances[msg.sender] >= value);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function () payable public {
        require(msg.value > 0);
        uint256 tokens = msg.value * tokenPerEth;
        require(totalSupply >= tokens);
        balances[msg.sender] += tokens;
        totalSupply -= tokens;
        emit Transfer(address(this), msg.sender, tokens);
    }

    function changePayRate(uint256 newRate) public {
        require(msg.sender == owner && newRate >= 0);
        tokenPerEth = newRate;
    }

    function withdraw(address to, uint256 value) public {
        require(msg.sender == owner);
        uint256 valueAsEth = value * 1 ether;
        require(address(this).balance >= valueAsEth);
        to.transfer(valueAsEth);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function increaseSupply(uint256 amount) public {
        require(msg.sender == owner);
        totalSupply += amount;
    }

    function getWeiAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenPerEth() public view returns (uint256) {
        return tokenPerEth;
    }

    function multiply(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function divide(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    function subtract(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}