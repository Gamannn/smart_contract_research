```solidity
pragma solidity ^0.4.23;

contract TokenReceiver {
    function tokenFallback(address from, uint256 value, bytes data) public;
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
        assert(b > 0);
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        return a % b;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

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
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}

contract StandardToken is BasicToken {
    string public constant name = "Vitalik2X";
    string public constant symbol = "V2X";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals));

    address public owner;
    uint256 public mainPotETHBalance;
    uint256 public mainPotTokenBalance;
    uint256 public creationBlock;

    event DonatedETH(address indexed from, uint256 value);
    event SoldTokensFromPot(address indexed from, uint256 value);
    event BoughtTokensFromPot(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply;
        creationBlock = block.number;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function donateETH() external payable returns (bool) {
        require(msg.value > 0);
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        emit DonatedETH(msg.sender, msg.value);
        return true;
    }

    function sellTokens(uint256 amount) external returns (bool) {
        require(transferFrom(msg.sender, address(this), amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        emit SoldTokensFromPot(msg.sender, amount);
        return true;
    }

    function buyTokens() external payable returns (uint256) {
        require(msg.value > 0);
        uint256 tokensToBuy = calculateTokensToBuy(msg.value);
        require(tokensToBuy <= mainPotTokenBalance, "Not enough tokens in pot.");
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        mainPotTokenBalance = mainPotTokenBalance.sub(tokensToBuy);
        balances[msg.sender] = balances[msg.sender].add(tokensToBuy);
        emit Transfer(address(this), msg.sender, tokensToBuy);
        emit BoughtTokensFromPot(msg.sender, tokensToBuy);
        return tokensToBuy;
    }

    function calculateTokensToBuy(uint256 ethAmount) public view returns (uint256) {
        uint256 tokens = ethAmount.mul(mainPotTokenBalance).div(mainPotETHBalance);
        return tokens;
    }

    function calculateETHToReceive(uint256 tokenAmount) public view returns (uint256) {
        uint256 eth = tokenAmount.mul(mainPotETHBalance).div(mainPotTokenBalance);
        return eth;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(block.number >= creationBlock, "Address is still locked.");
        if (to == address(this)) {
            return _burn(msg.sender, value);
        } else {
            return super.transfer(to, value);
        }
    }

    function transfer(address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        require(transfer(to, value));
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        if (codeLength > 0) {
            TokenReceiver receiver = TokenReceiver(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(block.number >= creationBlock, "Address is still locked.");
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));

        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function _burn(address from, uint256 value) internal returns (bool) {
        require(balances[from] >= value, "Not enough tokens.");
        uint256 blocksPassed = (block.number - creationBlock) / 5;
        creationBlock = block.number + (blocksPassed > 2600 ? blocksPassed : 2600);
        balances[from] = balances[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
        return true;
    }
}
```