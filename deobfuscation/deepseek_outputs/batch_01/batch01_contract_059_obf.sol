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

    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns (bool success) {
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
    uint8 public decimals = 6;

    event LogTransfer(address sender, address receiver, uint amount);
    event Clearing(address receiver, uint256 amount);

    struct IcoState {
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
        uint256 totalSupply;
        uint256 cntMembers;
        uint8 decimals;
        uint256 initialRate;
    }

    IcoState public icoState;

    function CccTokenIco() {
        icoState.cntMembers = 0;
        icoState.startTimestamp = now - 11 days;
        icoState.baseowner = msg.sender;
        icoState.minCap = 3000000 * (uint256(10) ** icoState.decimals);
        icoState.maxCap = 200000000 * (uint256(10) ** icoState.decimals);
        icoState.totalSupply = icoState.maxCap;
        balances[icoState.baseowner] = icoState.totalSupply;
        Transfer(0x0, icoState.baseowner, icoState.totalSupply);
    }

    function bva(address partner, uint256 value, uint256 rate, address adviser) isIcoOpen payable public {
        uint256 tokenAmount = calculateTokenAmount(value);
        if(msg.value != 0) {
            tokenAmount = calculateTokenCount(msg.value, icoState.avgRate);
        } else {
            require(msg.sender == icoState.stuff);
            icoState.avgRate = icoState.avgRate.add(rate).div(2);
        }

        if(msg.value != 0) {
            uint256 teamaShare = msg.value.mul(7).div(100);
            Clearing(icoState.teama, teamaShare);
            icoState.teama.transfer(teamaShare);

            uint256 teambShare = msg.value.mul(12).div(1000);
            Clearing(icoState.teamb, teambShare);
            icoState.teamb.transfer(teambShare);

            uint256 teamcShare = msg.value.mul(9).div(1000);
            Clearing(icoState.teamc, teamcShare);
            icoState.teamc.transfer(teamcShare);

            uint256 stuffShare = msg.value.mul(9).div(1000);
            Clearing(icoState.stuff, stuffShare);
            icoState.stuff.transfer(stuffShare);

            uint256 founderShare = msg.value.mul(70).div(100);
            Clearing(icoState.founder, founderShare);
            icoState.founder.transfer(founderShare);

            if(partner != adviser) {
                uint256 adviserShare = msg.value.mul(20).div(100);
                Clearing(adviser, adviserShare);
                adviser.transfer(adviserShare);
            }
        }

        icoState.totalRaised = icoState.totalRaised.add(tokenAmount);
        balances[icoState.baseowner] = balances[icoState.baseowner].sub(tokenAmount);
        balances[partner] = balances[partner].add(tokenAmount);
        Transfer(icoState.baseowner, partner, tokenAmount);
        icoState.cntMembers = icoState.cntMembers.add(1);
    }

    function() isIcoOpen payable public {
        if(msg.value != 0) {
            uint256 tokenAmount = calculateTokenCount(msg.value, icoState.avgRate);

            uint256 teamaShare = msg.value.mul(7).div(100);
            Clearing(icoState.teama, teamaShare);
            icoState.teama.transfer(teamaShare);

            uint256 teambShare = msg.value.mul(12).div(1000);
            Clearing(icoState.teamb, teambShare);
            icoState.teamb.transfer(teambShare);

            uint256 teamcShare = msg.value.mul(9).div(1000);
            Clearing(icoState.teamc, teamcShare);
            icoState.teamc.transfer(teamcShare);

            uint256 stuffShare = msg.value.mul(9).div(1000);
            Clearing(icoState.stuff, stuffShare);
            icoState.stuff.transfer(stuffShare);

            uint256 founderShare = msg.value.mul(70).div(100);
            Clearing(icoState.founder, founderShare);
            icoState.founder.transfer(founderShare);

            icoState.totalRaised = icoState.totalRaised.add(tokenAmount);
            balances[icoState.baseowner] = balances[icoState.baseowner].sub(tokenAmount);
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            Transfer(icoState.baseowner, msg.sender, tokenAmount);
            icoState.cntMembers = icoState.cntMembers.add(1);
        }
    }

    function calculateTokenAmount(uint256 count) constant returns(uint256) {
        uint256 icoDeflator = getIcoDeflator();
        return count.mul(icoDeflator).div(100);
    }

    function calculateTokenCount(uint256 weiAmount, uint256 rate) constant returns(uint256) {
        if(rate == 0) revert();
        uint256 icoDeflator = getIcoDeflator();
        return weiAmount.div(rate).mul(icoDeflator).div(100);
    }

    function getIcoDeflator() constant returns (uint256) {
        if (now <= icoState.startTimestamp + 15 days) {
            return 138;
        } else if (now <= icoState.startTimestamp + 29 days) {
            return 123;
        } else if (now <= icoState.startTimestamp + 43 days) {
            return 115;
        } else {
            return 109;
        }
    }

    function finalize(uint256 weiAmount) isIcoFinished isStuff payable public {
        if(msg.sender == icoState.founder) {
            icoState.founder.transfer(weiAmount);
        }
    }

    function transfer(address _to, uint _value) isIcoFinished returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) isIcoFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier isStuff() {
        require(msg.sender == icoState.stuff || msg.sender == icoState.founder);
        _;
    }

    modifier isIcoOpen() {
        require(now >= icoState.startTimestamp);
        require(now <= icoState.startTimestamp + 14 days || now >= icoState.startTimestamp + 19 days);
        require(now <= (icoState.startTimestamp + icoState.durationSeconds) || icoState.totalRaised < icoState.minCap);
        require(icoState.totalRaised <= icoState.maxCap);
        _;
    }

    modifier isIcoFinished() {
        require(now >= icoState.startTimestamp);
        require(icoState.totalRaised >= icoState.maxCap || (now >= (icoState.startTimestamp + icoState.durationSeconds) && icoState.totalRaised >= icoState.minCap));
        _;
    }
}