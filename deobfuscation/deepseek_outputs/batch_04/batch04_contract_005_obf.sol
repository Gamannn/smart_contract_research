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
    event Dividends(uint256 round, uint256 amount);
    event ClaimDividends(address indexed investor, uint256 amount);

    uint256 public totalDividendsAmount;
    uint256 public totalDividendsRounds;
    uint256 public totalUnPayedDividendsAmount;

    function totalDividends() public constant returns (uint256) {
        return totalDividendsAmount;
    }

    function totalDividendsRounds() public constant returns (uint256) {
        return totalDividendsRounds;
    }

    function totalUnPayedDividends() public constant returns (uint256) {
        return totalUnPayedDividendsAmount;
    }

    function dividendsOf(address investor) public constant returns (uint256);
    function claimDividends() public;
    function addDividends() payable public {
        require(msg.value > 0);
        totalDividendsAmount = totalDividendsAmount.add(msg.value);
        totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.add(msg.value);
        totalDividendsRounds += 1;
        Dividends(totalDividendsRounds, msg.value);
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
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

contract Token is ERC20, DividendManager {
    string public name;
    string public symbol;
    uint8 public decimals;
    function availableTokens() public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function burnRemaining() public;
    function burn(address burner) public;
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    Token public tokenContract;
    function TokenSale(address tokenAddress) public {
        require(tokenAddress != address(0));
        tokenContract = Token(tokenAddress);
    }
}

contract ESTTokenSale is Ownable, TokenSale {
    using SafeMath for uint256;

    enum State { PrivatePreSale, PreSale, ActiveICO, ICOComplete }
    State public saleState;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;
    uint256 public rate;
    address public wallet;
    mapping(address => uint256) public privatePreSaleAllowance;

    function ESTTokenSale(address tokenAddress) public TokenSale(tokenAddress) {
        saleState = State.PrivatePreSale;
        startTime = 0;
        endTime = 0;
        weiRaised = 0;
        rate = 0;
        wallet = address(0);
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(isOpen());
        uint256 weiAmount = msg.value;
        uint256 tokens = calculateTokens(weiAmount);
        uint256 available = tokenContract.availableTokens();
        require(available >= tokens);
        if(saleState == State.PrivatePreSale) {
            require(privatePreSaleAllowance[beneficiary] > 0);
            if(privatePreSaleAllowance[beneficiary] < tokens) {
                tokens = privatePreSaleAllowance[beneficiary];
            }
        }
        weiRaised = weiRaised.add(weiAmount);
        wallet.transfer(weiAmount.mul(75).div(100));
        tokenContract.transferFrom(owner, beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function addPrivatePreSaleAllowance(address beneficiary, uint256 amount) public onlyOwner {
        require(saleState == State.PrivatePreSale);
        privatePreSaleAllowance[beneficiary] = privatePreSaleAllowance[beneficiary].add(amount);
    }

    function startPreSale() public onlyOwner {
        require(saleState == State.PrivatePreSale);
        saleState = State.PreSale;
    }

    function startICO() public onlyOwner {
        require(saleState == State.PreSale);
        saleState = State.ActiveICO;
        startTime = now;
        endTime = startTime + 7 weeks;
    }

    function finalizeICO() public onlyOwner {
        require(saleState == State.ActiveICO);
        require(tokenContract.availableTokens() == 0 || (endTime > 0 && now >= endTime));
        require(weiRaised > 0);
        saleState = State.ICOComplete;
        endTime = uint256(4233600);
    }

    function withdraw() public onlyOwner {
        require(saleState == State.ICOComplete);
        require(endTime + 60 days <= now);
        wallet.transfer(this.balance);
    }

    function isClosed() public view returns (bool) {
        return saleState == State.ICOComplete || tokenContract.availableTokens() == 0 || (endTime > 0 && now >= endTime);
    }

    function calculateTokens(uint256 weiAmount) public view returns(uint256) {
        uint256 baseTokens = weiAmount.mul(rate);
        uint256 bonusPercent = getBonusPercent(weiAmount);
        if(saleState == State.PrivatePreSale || saleState == State.PreSale) {
            bonusPercent = bonusPercent.add(50);
        } else if(saleState == State.ActiveICO) {
            if((now - startTime) < 1 weeks) {
                bonusPercent = bonusPercent.add(30);
            } else if((now - startTime) < 3 weeks) {
                bonusPercent = bonusPercent.add(10);
            }
        }
        return applyBonus(baseTokens, bonusPercent);
    }

    function applyBonus(uint256 baseAmount, uint256 bonusPercent) internal pure returns(uint256) {
        if(bonusPercent == 0) return baseAmount;
        return baseAmount.add(calculateBonus(baseAmount, bonusPercent));
    }

    function calculateBonus(uint256 amount, uint256 bonusPercent) internal pure returns(uint256) {
        if(bonusPercent == 0) return 0;
        return amount.mul(bonusPercent).div(100);
    }

    function getBonusPercent(uint256 weiAmount) internal pure returns(uint256) {
        if(weiAmount >= 1000 ether) {
            return 50;
        }
        if(weiAmount >= 500 ether) {
            return 30;
        }
        if(weiAmount >= 100 ether) {
            return 15;
        }
        if(weiAmount >= 50 ether) {
            return 10;
        }
        if(weiAmount >= 10 ether) {
            return 5;
        }
        return 0;
    }

    function isOpen() internal view returns (bool) {
        bool nonZero = msg.value != 0;
        return isClosed() == false && nonZero;
    }

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
}