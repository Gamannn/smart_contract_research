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

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Owned {
    address public owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract CIPToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public name = "CIP Token";
    string public symbol = "CIP";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event FreezeIn(address[] indexed accounts, bool frozen);
    event FreezeOut(address[] indexed accounts, bool frozen);

    constructor() public {
        totalSupply = 4500000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function internalTransfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balanceOf[from] >= value);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[msg.sender]);
        uint256 availableBalance = balanceOf[msg.sender].sub(allowance[msg.sender][msg.sender]);
        require(value <= availableBalance);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(allowance[from][msg.sender] >= value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        internalTransfer(from, to, value);
        return true;
    }

    function updateTokenDetails(string newName, string newSymbol) public onlyOwner {
        name = newName;
        symbol = newSymbol;
    }

    function freezeAccount(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        allowance[account][msg.sender] = allowance[account][msg.sender].add(value);
    }

    function unfreezeAccount(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        require(value <= allowance[account][msg.sender]);
        allowance[account][msg.sender] = allowance[account][msg.sender].sub(value);
    }

    function () public payable {}
}