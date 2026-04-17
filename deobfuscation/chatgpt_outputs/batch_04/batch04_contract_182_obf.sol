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
        uint256 c = a - b;
        return c;
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
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract StandardToken is BasicToken {
    function transferAndCall(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(this));
        require(transfer(_to, _value));
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        if (codeLength > 0) {
            TokenReceiver receiver = TokenReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        return true;
    }
}

contract Vitalik2XToken is StandardToken {
    string public constant name = "Vitalik2X";
    string public constant symbol = "V2X";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10 ** uint256(decimals);

    address public owner;
    uint256 public creationBlock;
    uint256 public mainPotTokenBalance;
    uint256 public mainPotETHBalance;

    event DonatedTokens(address indexed donor, uint256 amount);
    event DonatedETH(address indexed donor, uint256 amount);
    event SoldTokensFromPot(address indexed buyer, uint256 amount);
    event BoughtTokensFromPot(address indexed buyer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        creationBlock = block.number;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function donateTokens(uint256 amount) external returns (bool) {
        require(transfer(address(this), amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        emit DonatedTokens(msg.sender, amount);
        return true;
    }

    function donateETH() external payable returns (bool) {
        require(msg.value > 0);
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        emit DonatedETH(msg.sender, msg.value);
        return true;
    }

    function buyTokens(uint256 amount) external returns (bool) {
        uint256 ethAmount = calculateETHAmount(amount);
        require(ethAmount <= address(this).balance, "ETH amount exceeds balance.");
        require(transfer(msg.sender, amount));
        mainPotTokenBalance = mainPotTokenBalance.sub(amount);
        mainPotETHBalance = mainPotETHBalance.add(ethAmount);
        emit SoldTokensFromPot(msg.sender, amount);
        return true;
    }

    function sellTokens(uint256 amount) external payable returns (uint256) {
        require(msg.value > 0);
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount <= mainPotTokenBalance, "Token amount exceeds pot balance.");
        require(mainPotTokenBalance >= 1 finney, "Pot does not have enough tokens.");
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        mainPotTokenBalance = mainPotTokenBalance.sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        emit BoughtTokensFromPot(msg.sender, tokenAmount);
        return tokenAmount;
    }

    function calculateETHAmount(uint256 tokenAmount) public view returns (uint256) {
        return tokenAmount.mul(mainPotETHBalance).div(mainPotTokenBalance);
    }

    function calculateTokenAmount(uint256 ethAmount) public view returns (uint256) {
        return ethAmount.mul(mainPotTokenBalance).div(mainPotETHBalance);
    }

    function isLocked(address account) public view returns (bool) {
        return (block.number < creationBlock + 42000);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(block.number >= creationBlock, "Address is still locked.");
        if (to == address(this)) {
            return mintTokens(msg.sender, value);
        } else {
            return super.transfer(to, value);
        }
    }

    function mintTokens(address to, uint256 value) internal returns (bool) {
        require(balances[to] >= value, "Owner doesn't have enough tokens.");
        uint256 lockDuration = (block.number - creationBlock) / 5;
        creationBlock = block.number + (lockDuration > 1337 ? lockDuration : 1337);
        if (creationBlock >= block.number + 42000) {
            creationBlock = block.number + 42000;
        }
        require(mint(to, value), "Minting failed");
        emit Transfer(address(0), to, value);
        return true;
    }

    function mint(address to, uint256 value) internal returns (bool) {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        return true;
    }
}
```