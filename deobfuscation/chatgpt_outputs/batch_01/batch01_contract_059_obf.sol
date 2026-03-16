pragma solidity ^0.4.10;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract CccTokenIco is StandardToken {
    using SafeMath for uint256;

    string public name = "Crypto Credit Card Token";
    string public symbol = "CCCR";

    struct IcoData {
        address baseowner;
        address founder;
        address teamc;
        address teamb;
        address teama;
        address stuff;
        uint256 avgRate;
        uint256 maxCap;
        uint256 minCap;
        uint256 durationSeconds;
        uint256 startTimestamp;
        uint256 totalRaised;
        uint256 initialSupply;
        uint256 cntMembers;
        uint8 decimals;
    }

    IcoData public icoData;

    event LogTransfer(address indexed from, address indexed to, uint value);
    event Clearing(address indexed to, uint256 value);

    function CccTokenIco() public {
        icoData.baseowner = msg.sender;
        icoData.founder = 0xbb2efFab932a4c2f77Fc1617C1a563738D71B0a7;
        icoData.teamc = 0xE8726942a46E6C6B3C1F061c14a15c0053A97B6b;
        icoData.teamb = 0x21f0F5E81BEF4dc696C6BF0196c60a1aC797f953;
        icoData.teama = 0xfc6851324e2901b3ea6170a90Cc43BFe667D617A;
        icoData.stuff = 0x0CcCb9bAAdD61F9e0ab25bD782765013817821bD;
        icoData.decimals = 18;
        icoData.avgRate = uint256(10)**(18-icoData.decimals).div(460);
        icoData.maxCap = 200000000 * (uint256(10) ** icoData.decimals);
        icoData.minCap = 3000000 * (uint256(10) ** icoData.decimals);
        icoData.durationSeconds = uint256(86400 * 7 * 11);
        icoData.startTimestamp = now - 11 days;
        icoData.initialSupply = icoData.maxCap;
        balances[icoData.baseowner] = icoData.initialSupply;
        Transfer(0x0, icoData.baseowner, icoData.initialSupply);
    }

    function participate(address partner, uint256 weiAmount, uint256 rate, address adviser) isIcoOpen payable public {
        uint256 tokenAmount = calculateTokenAmount(weiAmount);
        if(msg.value != 0) {
            tokenAmount = calculateTokenCount(msg.value, icoData.avgRate);
        } else {
            require(msg.sender == icoData.stuff);
            icoData.avgRate = icoData.avgRate.add(rate).div(2);
        }
        if(msg.value != 0) {
            distributeFunds(msg.value);
        }
        icoData.totalRaised = icoData.totalRaised.add(tokenAmount);
        balances[icoData.baseowner] = balances[icoData.baseowner].sub(tokenAmount);
        balances[partner] = balances[partner].add(tokenAmount);
        Transfer(icoData.baseowner, partner, tokenAmount);
        icoData.cntMembers = icoData.cntMembers.add(1);
    }

    function() isIcoOpen payable public {
        if(msg.value != 0) {
            uint256 tokenAmount = calculateTokenCount(msg.value, icoData.avgRate);
            distributeFunds(msg.value);
            icoData.totalRaised = icoData.totalRaised.add(tokenAmount);
            balances[icoData.baseowner] = balances[icoData.baseowner].sub(tokenAmount);
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            Transfer(icoData.baseowner, msg.sender, tokenAmount);
            icoData.cntMembers = icoData.cntMembers.add(1);
        }
    }

    function calculateTokenAmount(uint256 count) constant returns(uint256) {
        uint256 icoDeflator = getIcoDeflator();
        return count.mul(icoDeflator).div(100);
    }

    function calculateTokenCount(uint256 weiAmount, uint256 rate) constant returns(uint256) {
        require(rate != 0);
        uint256 icoDeflator = getIcoDeflator();
        return weiAmount.div(rate).mul(icoDeflator).div(100);
    }

    function getIcoDeflator() constant returns (uint256) {
        if (now <= icoData.startTimestamp + 15 days) {
            return 138;
        } else if (now <= icoData.startTimestamp + 29 days) {
            return 123;
        } else if (now <= icoData.startTimestamp + 43 days) {
            return 115;
        } else {
            return 109;
        }
    }

    function finalize(uint256 weiAmount) isIcoFinished isStuff payable public {
        if(msg.sender == icoData.founder) {
            icoData.founder.transfer(weiAmount);
        }
    }

    function transfer(address _to, uint _value) isIcoFinished returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) isIcoFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier isStuff() {
        require(msg.sender == icoData.stuff || msg.sender == icoData.founder);
        _;
    }

    modifier isIcoOpen() {
        require(now >= icoData.startTimestamp);
        require(now <= icoData.startTimestamp + 14 days || now >= icoData.startTimestamp + 19 days);
        require(now <= (icoData.startTimestamp + icoData.durationSeconds) || icoData.totalRaised < icoData.minCap);
        require(icoData.totalRaised <= icoData.maxCap);
        _;
    }

    modifier isIcoFinished() {
        require(now >= icoData.startTimestamp);
        require(icoData.totalRaised >= icoData.maxCap || (now >= (icoData.startTimestamp + icoData.durationSeconds) && icoData.totalRaised >= icoData.minCap));
        _;
    }

    function distributeFunds(uint256 weiAmount) internal {
        Clearing(icoData.teama, weiAmount.mul(7).div(100));
        icoData.teama.transfer(weiAmount.mul(7).div(100));
        Clearing(icoData.teamb, weiAmount.mul(12).div(1000));
        icoData.teamb.transfer(weiAmount.mul(12).div(1000));
        Clearing(icoData.teamc, weiAmount.mul(9).div(1000));
        icoData.teamc.transfer(weiAmount.mul(9).div(1000));
        Clearing(icoData.stuff, weiAmount.mul(9).div(1000));
        icoData.stuff.transfer(weiAmount.mul(9).div(1000));
        Clearing(icoData.founder, weiAmount.mul(70).div(100));
        icoData.founder.transfer(weiAmount.mul(70).div(100));
    }
}