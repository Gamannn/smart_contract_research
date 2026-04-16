```solidity
pragma solidity ^0.4.24;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address to, uint256 value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) public constant returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) allowed;
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 allowanceAmount = allowed[from][msg.sender];
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowanceAmount.sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
    bool public mintingFinished = false;
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract CrowdsaleToken is MintableToken {
    string public constant name = "SmartRetail ICO";
    string public constant symbol = "SRI";
    uint32 public constant decimals = 18;
}

contract Crowdsale {
    using SafeMath for uint256;
    
    address public multisig;
    uint256 public rate;
    uint256 public softcap;
    uint256 public hardcap;
    uint256 public icoStart;
    uint256 public icoEnd;
    uint256 public tokensFor1EthP1;
    uint256 public tokensFor1EthP2;
    uint256 public tokensFor1EthP3;
    uint256 public tokensFor1EthP4;
    uint256 public tokensFor1EthP5;
    uint256 public tokensFor1EthP6;
    uint256 public icoStartP1;
    uint256 public icoStartP2;
    uint256 public icoStartP3;
    uint256 public icoStartP4;
    uint256 public icoStartP5;
    uint256 public icoStartP6;
    uint256 public totalSupply;
    
    CrowdsaleToken public token = new CrowdsaleToken();
    
    constructor() public {
        multisig = 0xF15eE43d0345089625050c08b482C3f2285e4F12;
        rate = 35000;
        softcap = 5000 ether;
        hardcap = 1000000 ether;
        icoStart = 1531267200;
        icoEnd = 1541894400;
        tokensFor1EthP1 = 35000;
        tokensFor1EthP2 = 33250;
        tokensFor1EthP3 = 31500;
        tokensFor1EthP4 = 29750;
        tokensFor1EthP5 = 28000;
        tokensFor1EthP6 = 26250;
        icoStartP1 = 1531267200;
        icoStartP2 = 1533945600;
        icoStartP3 = 1536624000;
        icoStartP4 = 1539216000;
        icoStartP5 = 1541894400;
        icoStartP6 = 1544486400;
        totalSupply = 1000000000 * (10 ** 18);
        
        token.mint(this, totalSupply);
        token.transferOwnership(address(this));
    }
    
    function createTokens() public payable {
        require(
            (now >= icoStart) && 
            (now <= icoEnd) && 
            (token.totalSupply() < totalSupply)
        );
        
        uint256 tokens = rate.mul(msg.value).div(1 ether);
        uint256 bonusTokens = 0;
        
        if (now < icoStartP2) {
            rate = tokensFor1EthP1;
        } else if (now >= icoStartP2 && now < icoStartP3) {
            rate = tokensFor1EthP2;
        } else if (now >= icoStartP3 && now < icoStartP4) {
            rate = tokensFor1EthP3;
        } else if (now >= icoStartP4 && now < icoStartP5) {
            rate = tokensFor1EthP4;
        } else if (now >= icoStartP5 && now < icoStartP6) {
            rate = tokensFor1EthP5;
        } else if (now >= icoStartP6 && now < icoEnd) {
            rate = tokensFor1EthP6;
        }
        
        tokens = rate.mul(msg.value).div(1 ether);
        
        if (token.totalSupply().add(tokens) > totalSupply) {
            tokens = totalSupply.sub(token.totalSupply());
            bonusTokens = tokens.mul(1 ether).div(rate).sub(msg.value);
        }
        
        token.transfer(msg.sender, tokens);
        
        if (bonusTokens != 0) {
            msg.sender.transfer(bonusTokens);
            balances[msg.sender] = balances[msg.sender].add(bonusTokens);
        }
        
        if (token.totalSupply() >= hardcap) {
            multisig.transfer(address(this).balance);
        }
    }
    
    function refund() public {
        require(
            (now > icoEnd) && 
            (token.totalSupply() < softcap)
        );
        
        uint256 value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    }
    
    function withdraw() public onlyOwner {
        require(token.totalSupply() > softcap);
        multisig.transfer(address(this).balance);
    }
    
    function finishMinting() public onlyOwner {
        if (now > icoEnd) {
            token.finishMinting();
            token.transferOwnership(multisig);
        }
    }
    
    function() external payable {
        createTokens();
    }
}
```