pragma solidity ^0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
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

contract DetailedERC20 is ERC20 {
    constructor(string name, string symbol, uint8 decimals) public {
        s2c.name = name;
        s2c.symbol = symbol;
        s2c.decimals = decimals;
    }
}

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        s2c.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == s2c.owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(s2c.owner);
        s2c.owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(s2c.owner, newOwner);
        s2c.owner = newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!s2c.mintingFinished);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == s2c.owner);
        _;
    }

    function mint(address to, uint256 amount) onlyMinter canMint public returns (bool) {
        s2c.totalSupply = s2c.totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        s2c.mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _burn(address burner, uint256 value) internal {
        require(value <= balances[burner]);
        balances[burner] = balances[burner].sub(value);
        s2c.totalSupply = s2c.totalSupply.sub(value);
        emit Burn(burner, value);
        emit Transfer(burner, address(0), value);
    }
}

contract ClubToken is StandardToken, DetailedERC20, MintableToken, BurnableToken {
    modifier onlyMinter() {
        require(
            msg.sender == s2c.cloversController ||
            msg.sender == s2c.clubTokenController ||
            msg.sender == s2c.owner
        );
        _;
    }

    constructor(string name, string symbol, uint8 decimals) public DetailedERC20(name, symbol, decimals) {}

    function () public payable {}

    function setCloversController(address cloversController) public onlyOwner {
        require(cloversController != 0);
        s2c.cloversController = cloversController;
    }

    function setClubTokenController(address clubTokenController) public onlyOwner {
        require(clubTokenController != 0);
        s2c.clubTokenController = clubTokenController;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        if (msg.sender != s2c.clubTokenController && msg.sender != s2c.cloversController) {
            require(value <= allowed[from][msg.sender]);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        }
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public {
        value;
        revert();
    }

    function burn(address burner, uint256 value) public onlyMinter {
        _burn(burner, value);
    }

    function moveEth(address to, uint256 amount) public onlyMinter {
        require(this.balance >= amount);
        to.transfer(amount);
    }

    function moveTokens(address to, uint256 amount, address tokenContract) public onlyMinter returns (bool) {
        require(amount <= StandardToken(tokenContract).balanceOf(this));
        return StandardToken(tokenContract).transfer(to, amount);
    }

    function approveTokens(address spender, uint256 amount, address tokenContract) public onlyMinter returns (bool) {
        return StandardToken(tokenContract).approve(spender, amount);
    }

    struct Storage {
        address cloversController;
        address clubTokenController;
        bool mintingFinished;
        address owner;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalSupply;
    }

    Storage s2c = Storage(address(0), address(0), false, address(0), 0, "", "", 0);
}