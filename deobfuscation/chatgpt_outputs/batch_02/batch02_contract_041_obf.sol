```solidity
pragma solidity ^0.4.20;

contract TokenContract {
    using SafeMath for uint;

    address public owner;
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public dividends;
    mapping(address => int256) public payoutsTo;
    uint256 public totalSupply;
    uint256 constant internal magnitude = 2**64;
    uint256 constant internal dividendFee = 10; // 10% dividend fee

    event onTokenSell(address indexed customerAddress, uint256 tokensSold, uint256 etherEarned);
    event onReinvestment(address indexed customerAddress, uint256 etherReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 etherWithdrawn);

    function TokenContract() public {
        owner = msg.sender;
    }

    function tokenPrice() public view returns(uint) {
        return 1 ether;
    }

    function calculateTokensReceived(uint _incomingEther) public view returns(uint) {
        return _incomingEther.div(tokenPrice());
    }

    function calculateEtherReceived(uint _tokensToSell) public view returns(uint) {
        return _tokensToSell.mul(tokenPrice());
    }

    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        return dividendsOf(msg.sender);
    }

    function dividendsOf(address _customerAddress) view public returns(uint) {
        return (uint256((int256(dividendFee * tokenBalance[_customerAddress]) - payoutsTo[_customerAddress])) / magnitude);
    }

    function buyTokens() public payable {
        purchaseTokens(msg.value);
    }

    function purchaseTokens(uint256 _incomingEther) private {
        address _customerAddress = msg.sender;
        uint256 _dividends = _incomingEther.div(dividendFee);
        uint256 _taxedEther = _incomingEther.sub(_dividends);
        uint256 _amountOfTokens = calculateTokensReceived(_taxedEther);
        require(_amountOfTokens > 0 && _amountOfTokens.add(totalSupply) > totalSupply);

        if (referrals[_customerAddress] == 0 && msg.sender != owner) {
            referrals[_customerAddress] = owner;
            referralBalance[owner] = referralBalance[owner].add(_dividends);
        } else {
            referralBalance[referrals[_customerAddress]] = referralBalance[referrals[_customerAddress]].add(_dividends);
        }

        totalSupply = totalSupply.add(_amountOfTokens);
        tokenBalance[_customerAddress] = tokenBalance[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (dividendFee * _amountOfTokens - (_taxedEther * magnitude));
        payoutsTo[_customerAddress] += _updatedPayouts;

        onTokenPurchase(_customerAddress, _incomingEther, _amountOfTokens, _dividends);
    }

    function sellTokens(uint256 _amountOfTokens) public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalance[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ether = calculateEtherReceived(_tokens);
        uint256 _dividends = _ether.div(dividendFee);
        uint256 _taxedEther = _ether.sub(_dividends);

        totalSupply = totalSupply.sub(_tokens);
        tokenBalance[_customerAddress] = tokenBalance[_customerAddress].sub(_tokens);

        int256 _updatedPayouts = (int256) (dividendFee * _tokens + (_taxedEther * magnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        onTokenSell(_customerAddress, _tokens, _taxedEther);
    }

    function withdraw() public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(true);
        payoutsTo[_customerAddress] += (int256) (_dividends * magnitude);
        _customerAddress.transfer(_dividends);
        onWithdraw(_customerAddress, _dividends);
    }

    function reinvest() public {
        uint256 _dividends = myDividends(false);
        payoutsTo[msg.sender] += (int256) (_dividends * magnitude);
        purchaseTokens(_dividends);
        onReinvestment(msg.sender, _dividends, calculateTokensReceived(_dividends));
    }

    function onTokenPurchase(address _customerAddress, uint256 _incomingEther, uint256 _amountOfTokens, uint256 _dividends) internal {
        // Event logic here
    }
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
```