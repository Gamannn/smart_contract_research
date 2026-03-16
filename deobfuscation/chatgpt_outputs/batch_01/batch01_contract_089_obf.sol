```solidity
pragma solidity ^0.4.15;

contract ERC20 {
    function balanceOf(address owner) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Extended is ERC20 {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract StandardToken is ERC20Extended, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        var _allowance = allowed[from][msg.sender];

        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));

        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
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

    function mint(address to, uint256 amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract GlobalCryptoBank is MintableToken {
    string public constant name = "Global Crypto Bank";
    string public constant symbol = "BANK";

    function GlobalCryptoBank() {
        mint(owner, INITIAL_SUPPLY);
        transfer(0x0e2Bec7F14F244c5D1b4Ce14f48dcDb88fB61690, 2000000 * 1 ether);
        finishMinting();
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

    GlobalCryptoBank public token = new GlobalCryptoBank();

    struct CrowdsaleData {
        uint256 soldTokens;
        uint256 bountyPercent;
        uint256 founderPercent;
        uint256 rate;
        uint256 isoEndDate;
        uint256 isoStartDate;
        uint256 preIsoEndDate;
        uint256 preIsoStartDate;
        uint256 isoTokenLimit;
        uint256 preIsoTokenLimit;
        address bountyAddress;
        address founderAddress;
        uint256 INITIAL_SUPPLY;
        uint32 decimals;
        bool mintingFinished;
        address owner;
        uint256 totalSupply;
    }

    CrowdsaleData public s2c = CrowdsaleData(
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, address(0), address(0), 50000000 * 1 ether, 18, false, address(0), 0
    );

    function Crowdsale() payable {
        s2c.founderAddress = 0xF12B75857E56727c90fc473Fe18C790B364468eD;
        s2c.bountyAddress = 0x0e2Bec7F14F244c5D1b4Ce14f48dcDb88fB61690;
        s2c.founderPercent = 90;
        s2c.bountyPercent = 10;
        s2c.rate = 300 * 1 ether;
        s2c.preIsoStartDate = 1509321600;
        s2c.preIsoEndDate = 1511049600;
        s2c.isoStartDate = 1511568000;
        s2c.isoEndDate = 1514678399;
        s2c.preIsoTokenLimit = 775000 * 1 ether;
        s2c.isoTokenLimit = 47225000 * 1 ether;
    }

    modifier isUnderPreIsoLimit(uint value) {
        require((s2c.soldTokens + s2c.rate.mul(value).div(1 ether) + s2c.rate.mul(value).div(1 ether).mul(getPreIsoBonusPercent(value).div(100))) <= s2c.preIsoTokenLimit);
        _;
    }

    modifier isUnderIsoLimit(uint value) {
        require((s2c.soldTokens + s2c.rate.mul(value).div(1 ether) + s2c.rate.mul(value).div(1 ether).mul(getIsoBonusPercent(value).div(100))) <= s2c.isoTokenLimit);
        _;
    }

    function getPreIsoBonusPercent(uint value) private returns (uint) {
        uint eth = value.div(1 ether);
        uint bonusPercent = 0;

        if (now >= s2c.preIsoStartDate && now <= s2c.preIsoStartDate + 2 days) {
            bonusPercent += 35;
        } else if (now >= s2c.preIsoStartDate + 2 days && now <= s2c.preIsoStartDate + 7 days) {
            bonusPercent += 33;
        } else if (now >= s2c.preIsoStartDate + 7 days && now <= s2c.preIsoStartDate + 14 days) {
            bonusPercent += 31;
        } else if (now >= s2c.preIsoStartDate + 14 days && now <= s2c.preIsoStartDate + 21 days) {
            bonusPercent += 30;
        }

        if (eth >= 1 && eth < 10) {
            bonusPercent += 2;
        } else if (eth >= 10 && eth < 50) {
            bonusPercent += 4;
        } else if (eth >= 50 && eth < 100) {
            bonusPercent += 8;
        } else if (eth >= 100) {
            bonusPercent += 10;
        }

        return bonusPercent;
    }

    function getIsoBonusPercent(uint value) private returns (uint) {
        uint eth = value.div(1 ether);
        uint bonusPercent = 0;

        if (now >= s2c.isoStartDate && now <= s2c.isoStartDate + 2 days) {
            bonusPercent += 20;
        } else if (now >= s2c.isoStartDate + 2 days && now <= s2c.isoStartDate + 7 days) {
            bonusPercent += 18;
        } else if (now >= s2c.isoStartDate + 7 days && now <= s2c.isoStartDate + 14 days) {
            bonusPercent += 15;
        } else if (now >= s2c.isoStartDate + 14 days && now <= s2c.isoStartDate + 21 days) {
            bonusPercent += 10;
        }

        if (eth >= 1 && eth < 10) {
            bonusPercent += 2;
        } else if (eth >= 10 && eth < 50) {
            bonusPercent += 4;
        } else if (eth >= 50 && eth < 100) {
            bonusPercent += 8;
        } else if (eth >= 100) {
            bonusPercent += 10;
        }

        return bonusPercent;
    }

    function buyPreICOTokens(uint value, address sender) private isUnderPreIsoLimit(value) {
        s2c.founderAddress.transfer(value.div(100).mul(s2c.founderPercent));
        s2c.bountyAddress.transfer(value.div(100).mul(s2c.bountyPercent));

        uint tokens = s2c.rate.mul(value).div(1 ether);
        uint bonusTokens = 0;
        uint bonusPercent = getPreIsoBonusPercent(value);
        bonusTokens = tokens.mul(bonusPercent).div(100);
        tokens += bonusTokens;
        s2c.soldTokens += tokens;
        token.transfer(sender, tokens);
    }

    function buyICOTokens(uint value, address sender) private isUnderIsoLimit(value) {
        s2c.founderAddress.transfer(value.div(100).mul(s2c.founderPercent));
        s2c.bountyAddress.transfer(value.div(100).mul(s2c.bountyPercent));

        uint tokens = s2c.rate.mul(value).div(1 ether);
        uint bonusTokens = 0;
        uint bonusPercent = getIsoBonusPercent(value);
        bonusTokens = tokens.mul(bonusPercent).div(100);
        tokens += bonusTokens;
        s2c.soldTokens += tokens;
        token.transfer(sender, tokens);
    }

    function() external payable {
        if (now >= s2c.preIsoStartDate && now < s2c.preIsoEndDate) {
            buyPreICOTokens(msg.value, msg.sender);
        } else if (now >= s2c.isoStartDate && now < s2c.isoEndDate) {
            buyICOTokens(msg.value, msg.sender);
        }
    }
}
```