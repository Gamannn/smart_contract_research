pragma solidity ^0.4.13;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

    function halt() external onlyOwner {
        halted = true;
    }

    function unhalt() external onlyOwner {
        halted = false;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract PreDGZToken is StandardToken, Haltable {
    using SafeMath for uint256;

    string public constant name = "Dogezer preDGZ Token";
    string public constant symbol = "preDGZ";
    uint8 public decimals = 8;
    uint256 public totalSupply = 200000000000000;

    struct Crowdsale {
        bool crowdsaleClosed;
        uint256 price;
        uint256 amountRaised;
        uint256 fundingGoal;
        uint256 duration;
        uint256 startTime;
        address beneficiary;
    }

    Crowdsale public crowdsale;

    function PreDGZToken() public {
        owner = msg.sender;
        crowdsale = Crowdsale({
            crowdsaleClosed: false,
            price: 0,
            amountRaised: 0,
            fundingGoal: 0,
            duration: 0,
            startTime: 1504270800,
            beneficiary: address(0)
        });
    }

    function () payable stopInEmergency public {
        require(msg.value >= 0.002 * 1 ether);
        require(crowdsale.crowdsaleClosed == false);
        require(crowdsale.fundingGoal >= crowdsale.amountRaised.add(msg.value));

        uint256 amount = msg.value;
        balances[msg.sender] = balances[msg.sender].add(amount);
        crowdsale.amountRaised = crowdsale.amountRaised.add(amount);
        transfer(msg.sender, amount.div(crowdsale.price));

        if (crowdsale.amountRaised == crowdsale.fundingGoal) {
            crowdsale.crowdsaleClosed = true;
            SaleFinished(crowdsale.amountRaised);
        }
    }

    function withdrawFunds(uint256 amountWithdraw) onlyOwner public {
        crowdsale.beneficiary.transfer(amountWithdraw);
    }

    function changeBeneficiary(address newBeneficiary) onlyOwner public {
        if (newBeneficiary != address(0)) {
            crowdsale.beneficiary = newBeneficiary;
        }
    }

    function finalizeSale() onlyOwner public {
        require(crowdsale.crowdsaleClosed == false);
        crowdsale.crowdsaleClosed = true;
        SaleFinished(crowdsale.amountRaised);
    }

    event SaleFinished(uint256 amountRaised);
}