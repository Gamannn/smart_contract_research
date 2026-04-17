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
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract StandardToken is ERC223 {
    using SafeMath for uint;

    mapping(address => uint) balances;

    function transfer(address _to, uint _value, bytes _data) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
    }

    function transfer(address _to, uint _value) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            bytes memory empty;
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, "");
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}

contract Doge2Token is StandardToken {
    string public name = "Doge2 Token";
    string public symbol = "DOGE2";
    uint256 public decimals = 8;
    uint256 public INITIAL_SUPPLY = 200000000000000;

    function Doge2Token() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function () payable {
        uint tokens = msg.value / 10000;
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        bytes memory empty;
        Transfer(msg.sender, msg.sender, tokens, empty);
    }
}
```