```solidity
pragma solidity ^0.4.20;

contract StrongHands {
    using SafeMath for uint256;
    
    address public owner;
    address public ceoAddress;
    
    mapping(address => address) public referrerOf;
    mapping(address => uint256) public referralBalance;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public tokenBalanceLedger;
    mapping(address => int256) public payoutsTo;
    
    uint256 public tokenSupply = 0;
    uint256 public profitPerShare = 0;
    uint256 public magnitude = 2**64;
    
    uint8 constant public entryFee = 50;
    uint256 constant public tokenPriceInitial = 0.0000000001 ether;
    uint256 constant public magnitudeFactor = 100000000;
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    function StrongHands() public {
        owner = msg.sender;
        ceoAddress = 0x93c5371707D2e015aEB94DeCBC7892eC1fa8dd80;
    }
    
    function ethereumToTokens(uint256 _ethereum) public view returns(uint256) {
        return _ethereum.div(tokenPrice());
    }
    
    function tokenPrice() public view returns(uint256) {
        return tokenPriceInitial.add(magnitudeFactor.mul(tokenSupply).div(magnitude));
    }
    
    function myDividends() public view returns(uint256) {
        return (dividendsOf(msg.sender).mul(98)).div(200);
    }
    
    function dividendsOf(address _customerAddress) public view returns(uint256) {
        return dividendsOf(_customerAddress);
    }
    
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256) ((int256)(profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / magnitude;
    }
    
    function contractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function balanceOf() public view returns(uint256) {
        return tokensToEthereum(tokenBalanceLedger[msg.sender]);
    }
    
    function buy() public payable {
        buyFor(msg.sender);
    }
    
    function buyFor(address _referredBy) public payable {
        require(_referredBy != msg.sender);
        
        if(referrerOf[msg.sender] == 0 && _referredBy != address(0)) {
            referrerOf[msg.sender] = _referredBy;
            referralCount[_referredBy] = referralCount[_referredBy].add(1);
        }
        
        purchaseTokens(msg.value);
    }
    
    function purchaseTokens(uint256 _incomingEthereum) private {
        address _customerAddress = msg.sender;
        uint256 _taxedEthereum = _incomingEthereum.mul(entryFee).div(100);
        uint256 _dividends = _taxedEthereum;
        uint256 _taxedEthereum2 = _incomingEthereum.sub(_taxedEthereum);
        uint256 _amountOfTokens = ethereumToTokens(_taxedEthereum2);
        uint256 _fee = _dividends * magnitude;
        
        require(_amountOfTokens > 0);
        
        if(tokenSupply > 0) {
            tokenSupply = tokenSupply.add(_amountOfTokens);
            profitPerShare += (_dividends * magnitude / (tokenSupply));
        } else {
            tokenSupply = _amountOfTokens;
        }
        
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].add(_amountOfTokens);
        
        int256 _updatedPayouts = (int256) ((profitPerShare * _amountOfTokens) - _fee);
        payoutsTo[_customerAddress] += _updatedPayouts;
        
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, referrerOf[_customerAddress]);
    }
    
    function sell(uint256 _amountOfTokens) public {
        withdraw();
        sellTokens(ethereumToTokens(_amountOfTokens));
        withdraw();
    }
    
    function withdraw() private {
        address _customerAddress = msg.sender;
        uint256 _dividends = dividendsOf(_customerAddress);
        
        payoutsTo[_customerAddress] += (int256) (_dividends * magnitude);
        _customerAddress.transfer(_dividends);
        
        onWithdraw(_customerAddress, _dividends);
    }
    
    function sellTokens(uint256 _amountOfTokens) private {
        address _customerAddress = msg.sender;
        require(tokenBalanceLedger[_customerAddress] > 0);
        require(_amountOfTokens <= tokenBalanceLedger[_customerAddress]);
        
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum(_tokens);
        uint256 _dividends = _ethereum;
        
        tokenSupply = tokenSupply.sub(_tokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_tokens);
        
        int256 _updatedPayouts = (int256) (profitPerShare * _tokens + (_dividends * magnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;
        
        onTokenSell(_customerAddress, _tokens, _dividends);
    }
    
    function reinvest() public {
        uint256 _dividends = dividendsOf(msg.sender);
        address _customerAddress = msg.sender;
        
        payoutsTo[_customerAddress] += (int256) (_dividends * magnitude);
        
        uint256 _taxedDividends = _dividends.mul(2);
        
        if(ethereumToTokens(_taxedDividends.add(referralBalance[msg.sender])) > 0) {
            purchaseTokens(_taxedDividends.add(referralBalance[msg.sender]));
            referralBalance[msg.sender] = 0;
        }
        
        address _referredBy = referrerOf[_customerAddress];
        
        if(_referredBy == address(0)) {
            uint256 _referralBonus = _taxedDividends.div(2);
            referralBalance[owner] = referralBalance[owner].add(_referralBonus);
            referralBalance[ceoAddress] = referralBalance[ceoAddress].add(_referralBonus);
        } else {
            referralBalance[_referredBy] = referralBalance[_referredBy].add(_taxedDividends);
        }
        
        onReinvestment(_customerAddress, _dividends, _taxedDividends);
    }
    
    function tokensToEthereum(uint256 _tokens) public view returns(uint256) {
        return _tokens.mul(tokenPrice());
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