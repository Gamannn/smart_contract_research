```solidity
pragma solidity ^0.4.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }
}

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency() {
        require(!halted);
        _;
    }

    modifier onlyInEmergency() {
        require(halted);
        _;
    }

    function halt() external onlyOwner {
        halted = true;
    }

    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) allowed;

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

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract DGZToken is StandardToken {
    using SafeMath for uint256;
    string public constant name = "Dogezer DGZ Token";
    string public constant symbol = "DGZ";
    uint8 public decimals = 8;
    uint256 public totalSupply = 100 * 0.1 finney;

    function DGZToken() public {
        totalSupply = totalSupply.mul(10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }
}

contract Crowdsale is Haltable {
    using SafeMath for uint256;

    string public name = "Dogezer Private Sale ITO";
    DGZToken public tokenReward;
    address public beneficiary;
    uint256 public startTime;
    uint256 public duration;
    uint256 public price;
    uint256 public discountPrice;
    uint256 public tokensContractBalance;
    bool public crowdsaleClosed = false;
    uint256 public tokenOwnerNumber = 0;
    uint256 public constant tokenOwnerNumberMax = 1000;
    uint256 public constant minPurchase = 25 ether;
    uint256 public constant discountValue = 100 ether;
    mapping(address => bool) public whiteList;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint256 amount, bool isContribution);

    modifier onlyAfterStart() {
        require(now >= startTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require(now < startTime + duration);
        _;
    }

    function Crowdsale(
        address addressOfTokenUsedAsReward,
        address addressOfBeneficiary,
        uint256 startTimeInSeconds,
        uint256 durationInSeconds,
        uint256 priceInWei,
        uint256 discountPriceInWei
    ) public {
        tokenReward = DGZToken(addressOfTokenUsedAsReward);
        beneficiary = addressOfBeneficiary;
        startTime = startTimeInSeconds;
        duration = durationInSeconds;
        price = priceInWei;
        discountPrice = discountPriceInWei;
        tokensContractBalance = tokenReward.balanceOf(this);
    }

    function () public payable stopInEmergency onlyAfterStart onlyBeforeEnd {
        require(msg.value >= minPurchase);
        require(!crowdsaleClosed);
        require(tokensContractBalance > 0);
        require(whiteList[msg.sender]);

        uint256 currentPrice = price;
        if (balanceOf[msg.sender] == 0) {
            require(tokenOwnerNumber < tokenOwnerNumberMax);
            tokenOwnerNumber++;
        }

        if (msg.value >= discountValue) {
            currentPrice = discountPrice;
        }

        uint256 amountSendTokens = msg.value.div(currentPrice);
        uint256 refund = 0;

        if (amountSendTokens > tokensContractBalance) {
            amountSendTokens = tokensContractBalance;
            refund = msg.value.sub(tokensContractBalance.mul(currentPrice));
            msg.sender.transfer(refund);
            FundTransfer(msg.sender, refund, true);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value.sub(refund));
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
        }

        tokenReward.transfer(msg.sender, amountSendTokens);
        FundTransfer(msg.sender, amountSendTokens, false);
        tokensContractBalance = tokensContractBalance.sub(amountSendTokens);
    }

    function joinWhiteList(address _address) public onlyOwner {
        if (_address != address(0)) {
            whiteList[_address] = true;
        }
    }

    function finalizeSale() public onlyOwner {
        require(!crowdsaleClosed);
        crowdsaleClosed = true;
    }

    function reopenSale() public onlyOwner {
        crowdsaleClosed = false;
    }

    function setPrice(uint256 _price) public onlyOwner {
        if (_price != 0) {
            price = _price;
        }
    }

    function setDiscount(uint256 _discountPrice) public onlyOwner {
        if (_discountPrice != 0) {
            discountPrice = _discountPrice;
        }
    }

    function fundWithdrawal(uint256 _amount) public onlyOwner {
        beneficiary.transfer(_amount);
    }

    function tokenWithdrawal(uint256 _amount) public onlyOwner {
        tokenReward.transfer(beneficiary, _amount);
        tokensContractBalance = tokensContractBalance.sub(_amount);
    }

    function changeBeneficiary(address _newBeneficiary) public onlyOwner {
        if (_newBeneficiary != address(0)) {
            beneficiary = _newBeneficiary;
        }
    }
}
```