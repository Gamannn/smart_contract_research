pragma solidity ^0.4.18;

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

contract DividendManager {
    using SafeMath for uint256;

    event Dividends(uint256 totalAmount, uint256 dividendAmount);
    event ClaimDividends(address indexed claimant, uint256 amount);

    uint256 public totalDividendsAmount = 0;
    uint256 public totalDividendsRounds = 0;
    uint256 public totalUnPayedDividendsAmount = 0;

    function getTotalDividendsAmount() public constant returns (uint256) {
        return totalDividendsAmount;
    }

    function getTotalDividendsRounds() public constant returns (uint256) {
        return totalDividendsRounds;
    }

    function getTotalUnPayedDividendsAmount() public constant returns (uint256) {
        return totalUnPayedDividendsAmount;
    }

    function claimDividends(address claimant) public constant returns (uint256);

    function distributeDividends() payable public {
        require(msg.value > 0);
        totalDividendsAmount = totalDividendsAmount.add(msg.value);
        totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.add(msg.value);
        totalDividendsRounds += 1;
        Dividends(totalDividendsAmount, msg.value);
    }
}

contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StandardToken is Token {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale is StandardToken, DividendManager {
    string public name = "Ethereum Slot Machine Token";
    string public symbol = "EST";
    uint8 public decimals = 18;

    enum State { PrivatePreSale, PreSale, ActiveICO, ICOComplete }
    State public currentState;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public weiRaised;

    address public wallet;

    mapping(address => uint256) public privatePreSaleAllocations;

    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        currentState = State.PrivatePreSale;
        startTime = 0;
        endTime = 0;
        weiRaised = 0;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 tokens = calculateTokenAmount(weiAmount);

        uint256 availableTokens = totalSupply();
        require(availableTokens >= tokens);

        if (currentState == State.PrivatePreSale) {
            require(privatePreSaleAllocations[beneficiary] > 0);
            if (privatePreSaleAllocations[beneficiary] < tokens) {
                tokens = privatePreSaleAllocations[beneficiary];
            }
        }

        weiRaised = weiRaised.add(weiAmount);
        wallet.transfer(weiAmount);

        transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function setPrivatePreSaleAllocation(address beneficiary, uint256 allocation) public onlyOwner {
        require(currentState == State.PrivatePreSale);
        privatePreSaleAllocations[beneficiary] = privatePreSaleAllocations[beneficiary].add(allocation);
    }

    function startPreSale() public onlyOwner {
        require(currentState == State.PrivatePreSale);
        currentState = State.PreSale;
    }

    function startICO() public onlyOwner {
        require(currentState == State.PreSale);
        currentState = State.ActiveICO;
        startTime = now;
        endTime = startTime + 7 weeks;
    }

    function finalizeICO() public onlyOwner {
        require(currentState == State.ActiveICO);
        require(totalSupply() == 0 || (endTime > 0 && now >= endTime));
        require(weiRaised > 0);
        currentState = State.ICOComplete;
        endTime = 0;
    }

    function withdrawFunds() public onlyOwner {
        require(currentState == State.ICOComplete);
        require(now >= endTime + 60 days);
        wallet.transfer(this.balance);
    }

    function isICOComplete() public view returns (bool) {
        return currentState == State.ICOComplete || totalSupply() == 0 || (endTime > 0 && now >= endTime);
    }

    function calculateTokenAmount(uint256 weiAmount) public view returns(uint256) {
        uint256 tokens = weiAmount.mul(rate);
        uint256 bonus = calculateBonus(weiAmount);

        if (currentState == State.PrivatePreSale || currentState == State.PreSale) {
            bonus = bonus.add(50);
        } else if (currentState == State.ActiveICO) {
            if ((now - startTime) < 1 weeks) {
                bonus = bonus.add(20);
            } else if ((now - startTime) < 3 weeks) {
                bonus = bonus.add(10);
            }
        }

        return tokens.mul(bonus).div(100);
    }

    function calculateBonus(uint256 weiAmount) internal pure returns(uint256) {
        if (weiAmount >= 1000 ether) {
            return 50;
        }
        if (weiAmount >= 500 ether) {
            return 30;
        }
        if (weiAmount >= 100 ether) {
            return 15;
        }
        if (weiAmount >= 50 ether) {
            return 10;
        }
        if (weiAmount >= 10 ether) {
            return 5;
        }
        return 0;
    }

    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return isICOComplete() == false && nonZeroPurchase;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Crowdsale() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}