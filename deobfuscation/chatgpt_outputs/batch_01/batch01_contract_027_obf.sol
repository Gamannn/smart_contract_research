```solidity
pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

pragma solidity ^0.4.24;

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
        return a / b;
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

pragma solidity ^0.4.24;

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
}

pragma solidity ^0.4.24;

contract ERC20 is ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

pragma solidity ^0.4.24;

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

pragma solidity ^0.4.24;

contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity ^0.4.24;

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address to, uint256 amount) hasMintPermission canMint public returns (bool) {
        s2c.totalSupply = s2c.totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

pragma solidity ^0.4.24;

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _burn(address who, uint256 value) internal {
        require(value <= balances[who]);
        balances[who] = balances[who].sub(value);
        s2c.totalSupply = s2c.totalSupply.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
    }
}

pragma solidity ^0.4.18;

contract ClubToken is StandardToken, DetailedERC20, MintableToken, BurnableToken {
    modifier onlyController() {
        require(
            msg.sender == s2c.controller1 ||
            msg.sender == s2c.controller2 ||
            msg.sender == owner
        );
        _;
    }

    constructor(string _name, string _symbol, uint8 _decimals)
        public
        DetailedERC20(_name, _symbol, _decimals)
    {}

    function () public payable {}

    function setController1(address _controller1) public onlyOwner {
        require(_controller1 != 0);
        s2c.controller1 = _controller1;
    }

    function setController2(address _controller2) public onlyOwner {
        require(_controller2 != 0);
        s2c.controller2 = _controller2;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);

        if (msg.sender != s2c.controller2 && msg.sender != s2c.controller1) {
            require(tokens <= allowed[from][msg.sender]);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function burn(uint256 value) public {
        value;
        revert();
    }

    function burn(address burner, uint256 value) public onlyController {
        _burn(burner, value);
    }

    function moveEth(address to, uint256 amount) public onlyController {
        require(this.balance >= amount);
        to.transfer(amount);
    }

    function moveTokens(address to, uint256 amount, address tokenContract) public onlyController returns (bool) {
        require(amount <= ERC20(tokenContract).balanceOf(this));
        return ERC20(tokenContract).transfer(to, amount);
    }

    function approveTokens(address spender, uint256 amount, address tokenContract) public onlyController returns (bool) {
        return ERC20(tokenContract).approve(spender, amount);
    }

    struct Scalar2Vector {
        address controller1;
        address controller2;
        bool mintingFinished;
        address owner;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalSupply;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0), address(0), false, address(0), 0, "", "", 0);
}
```