pragma solidity ^0.4.15;

contract ERC20Basic {
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    function Ownable() {
        storage.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == storage.owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        storage.owner = newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!storage.mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        storage.totalSupply = storage.totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        storage.mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract GlobalCryptoBank is MintableToken {
    string public constant name = "Global Crypto Bank";
    string public constant symbol = "BANK";

    function GlobalCryptoBank() {
        mint(storage.owner, storage.INITIAL_SUPPLY);
        transfer(0x0e2Bec7F14F244c5D1b4Ce14f48dcDb88fB61690, 2000000 * 1 ether);
        finishMinting();
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

    GlobalCryptoBank public token = new GlobalCryptoBank();

    function Crowdsale() payable {
        storage.founderAddress = 0xF12B75857E56727c90fc473Fe18C790B364468eD;
        storage.bountyAddress = 0x0e2Bec7F14F244c5D1b4Ce14f48dcDb88fB61690;
        storage.founderPercent = 90;
        storage.bountyPercent = 10;
        storage.rate = 300 * 1 ether;
        storage.preIsoStartDate = 1509321600;
        storage.preIsoEndDate = 1511049600;
        storage.isoStartDate = 1511568000;
        storage.isoEndDate = 1514678399;
        storage.preIsoTokenLimit = 775000 * 1 ether;
        storage.isoTokenLimit = 47225000 * 1 ether;
    }

    modifier isUnderPreIsoLimit(uint _value) {
        uint tokens = storage.rate.mul(_value).div(1 ether);
        uint bonusTokens = tokens.mul(getPreIsoBonusPercent(_value).div(100));
        require((storage.soldTokens + tokens + bonusTokens) <= storage.preIsoTokenLimit);
        _;
    }

    modifier isUnderIsoLimit(uint _value) {
        uint tokens = storage.rate.mul(_value).div(1 ether);
        uint bonusTokens = tokens.mul(getIsoBonusPercent(_value).div(100));
        require((storage.soldTokens + tokens + bonusTokens) <= storage.isoTokenLimit);
        _;
    }

    function getPreIsoBonusPercent(uint _value) private returns (uint) {
        uint eth = _value.div(1 ether);
        uint bonusPercent = 0;

        if (now >= storage.preIsoStartDate && now <= storage.preIsoStartDate + 2 days) {
            bonusPercent += 35;
        } else if (now >= storage.preIsoStartDate + 2 days && now <= storage.preIsoStartDate + 7 days) {
            bonusPercent += 33;
        } else if (now >= storage.preIsoStartDate + 7 days && now <= storage.preIsoStartDate + 14 days) {
            bonusPercent += 31;
        } else if (now >= storage.preIsoStartDate + 14 days && now <= storage.preIsoStartDate + 21 days) {
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

    function getIsoBonusPercent(uint _value) private returns (uint) {
        uint eth = _value.div(1 ether);
        uint bonusPercent = 0;

        if (now >= storage.isoStartDate && now <= storage.isoStartDate + 2 days) {
            bonusPercent += 20;
        } else if (now >= storage.isoStartDate + 2 days && now <= storage.isoStartDate + 7 days) {
            bonusPercent += 18;
        } else if (now >= storage.isoStartDate + 7 days && now <= storage.isoStartDate + 14 days) {
            bonusPercent += 15;
        } else if (now >= storage.isoStartDate + 14 days && now <= storage.isoStartDate + 21 days) {
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

    function buyPreICOTokens(uint _value, address sender) private isUnderPreIsoLimit(_value) {
        storage.founderAddress.transfer(_value.div(100).mul(storage.founderPercent));
        storage.bountyAddress.transfer(_value.div(100).mul(storage.bountyPercent));

        uint tokens = storage.rate.mul(_value).div(1 ether);
        uint bonusTokens = 0;
        uint bonusPercent = getPreIsoBonusPercent(_value);
        bonusTokens = tokens.mul(bonusPercent).div(100);
        tokens += bonusTokens;
        storage.soldTokens += tokens;
        token.transfer(sender, tokens);
    }

    function buyICOTokens(uint _value, address sender) private isUnderIsoLimit(_value) {
        storage.founderAddress.transfer(_value.div(100).mul(storage.founderPercent));
        storage.bountyAddress.transfer(_value.div(100).mul(storage.bountyPercent));

        uint tokens = storage.rate.mul(_value).div(1 ether);
        uint bonusTokens = 0;
        uint bonusPercent = getIsoBonusPercent(_value);
        bonusTokens = tokens.mul(bonusPercent).div(100);
        tokens += bonusTokens;
        storage.soldTokens += tokens;
        token.transfer(sender, tokens);
    }

    function() external payable {
        if (now >= storage.preIsoStartDate && now < storage.preIsoEndDate) {
            buyPreICOTokens(msg.value, msg.sender);
        } else if (now >= storage.isoStartDate && now < storage.isoEndDate) {
            buyICOTokens(msg.value, msg.sender);
        }
    }

    struct Storage {
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

    Storage storage = Storage(
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        address(0),
        address(0),
        50000000 * 1 ether,
        18,
        false,
        address(0),
        0
    );
}