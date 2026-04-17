```solidity
pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC223ReceivingContract {
    function tokenFallback(address from, uint value, bytes data);
}

contract ERC223 {
    uint public totalSupply;
    
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223Token is ERC223 {
    using SafeMath for uint;
    
    mapping(address => uint) balances;
    
    function transfer(address to, uint value, bytes data) {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        
        Transfer(msg.sender, to, value, data);
    }
    
    function transfer(address to, uint value) {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            bytes memory empty;
            receiver.tokenFallback(msg.sender, value, empty);
        }
        
        bytes memory empty;
        Transfer(msg.sender, to, value, empty);
    }
    
    function balanceOf(address owner) constant returns (uint balance) {
        return balances[owner];
    }
}

contract Doge2Token is ERC223Token {
    string public name = "Doge2 Token";
    string public symbol = "DOGE2";
    uint256 public decimals = 8;
    uint256 public totalSupply = 200000000000000;
    
    address public owner;
    uint256 public buyPrice = 10000;
    
    event Buy(address indexed buyer, uint256 tokens, uint256 value);
    
    function Doge2Token() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function() payable {
        uint tokens = msg.value / buyPrice;
        balances[owner] -= tokens;
        balances[msg.sender] += tokens;
        
        bytes memory empty;
        Transfer(owner, msg.sender, tokens, empty);
        Buy(msg.sender, tokens, msg.value);
    }
}
```