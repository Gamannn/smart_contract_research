```solidity
pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function Owned() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract ERC20Token is Owned {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function ERC20Token() payable Owned() public {
        totalSupply = 10000000000 * 10**18;
        balanceOf[owner] = totalSupply.sub(balanceOf[this]);
        Transfer(this, owner, balanceOf[owner]);
    }
    
    function() payable public {
        require(balanceOf[this] > 0);
        
        uint256 price = 21222 * 10**18;
        uint256 tokens = price.mul(msg.value).div(10**18);
        
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint256 refund = tokens.mul(10**18).div(price);
            msg.sender.transfer(msg.value.sub(refund));
        }
        
        require(tokens > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        balanceOf[this] = balanceOf[this].sub(tokens);
        Transfer(this, msg.sender, tokens);
    }
}

contract StandardToken is ERC20Token {
    using SafeMath for uint256;
    
    string public name = 'GAGAR';
    string public symbol = 'GAGAR';
    string public version = 'StandardToken.MEN';
    uint8 public decimals = 18;
    
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function StandardToken() payable ERC20Token() public {}
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(balanceOf[msg.sender] >= tokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(tokens);
        balanceOf[to] = balanceOf[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
}

contract GAGAR is StandardToken {
    function GAGAR() payable StandardToken() public {}
    
    function withdrawTokens() onlyOwner public {
        owner.transfer(this.balance);
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}
```