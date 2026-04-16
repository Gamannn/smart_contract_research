pragma solidity ^0.4.18;

contract Ox25c2579f50007fb9a9b07e759690d093017f2bb6 {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() public {
        owner = msg.sender;
        name = "ObfuscatedToken";
        symbol = "OBF";
        decimals = 18;
        totalSupply = 1000000 * 10**uint256(decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        require(to != address(0));
        
        balances[msg.sender] -= value;
        balances[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}