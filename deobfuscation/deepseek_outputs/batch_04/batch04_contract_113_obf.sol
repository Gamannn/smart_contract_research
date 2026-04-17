```solidity
pragma solidity ^0.4.26;

contract Tewken {
    using SafeMath for uint256;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    
    event onBuyEvent(
        address indexed buyer,
        uint256 tokensBought
    );
    
    event onSellEvent(
        address indexed seller,
        uint256 tokensSold
    );
    
    modifier isActive() {
        require(gameActive == true || msg.sender == owner);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPlayers() {
        require(players[msg.sender] == true);
        _;
    }
    
    modifier hasTokens() {
        require(myTokens() > 0);
        _;
    }
    
    address public owner;
    
    mapping(address => bool) private players;
    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) private referralBalance;
    
    uint256 private tokenPrice = 100000000000000;
    uint256 private contractValue;
    uint256 private tokenSupply;
    uint256 private totalDonations;
    uint256 private totalReferralRewards;
    
    uint8 private buyInFee = 5;
    uint8 private sellOutFee = 5;
    uint8 private devFee = 1;
    uint8 private referralFee = 8;
    uint256 private magnitude = 1000000000000000000;
    
    string public name = "Tewken";
    string public symbol = "TEW";
    
    bool private gameActive = false;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() payable public {
        donate();
    }
    
    function addPlayer(address _playerAddress) public onlyOwner {
        players[_playerAddress] = true;
    }
    
    function removePlayer(address _playerAddress) public onlyOwner {
        players[_playerAddress] = false;
    }
    
    function buyTokens(address _customerAddress) private returns(uint256) {
        uint256 _tokensBought = (contractValue.mul(magnitude)) / tokenPrice;
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].add(_tokensBought);
        tokenSupply = tokenSupply.add(_tokensBought);
        emit onBuyEvent(_customerAddress, _tokensBought);
        return _tokensBought;
    }
    
    function buyFromGame() public payable onlyPlayers returns(uint256) {
        uint256 _incomingEther = msg.value;
        address _customerAddress = msg.sender;
        require(_incomingEther >= 10000000000000);
        
        if (referralBalance[msg.sender] == 5) {
            totalReferralRewards = totalReferralRewards.add(1);
        }
        
        referralBalance[msg.sender] = referralBalance[msg.sender].add(_incomingEther);
        
        uint256 _devFee = (_incomingEther.mul(devFee)) / 100;
        uint256 _referralFee = (_incomingEther.mul(referralFee)) / 100;
        
        payOut(_referralFee, owner);
        
        uint256 _tokensBought = buyTokens(_incomingEther - _devFee - _referralFee, _customerAddress);
        
        contractValue = contractValue.add(_incomingEther);
        
        if (tokenSupply > magnitude) {
            tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
        }
        
        return _tokensBought;
    }
    
    function startGame() public payable isActive returns(uint256) {
        if (gameActive == false) {
            gameActive = true;
        }
        
        uint256 _incomingEther = msg.value;
        address _customerAddress = msg.sender;
        require(_incomingEther >= 10000000000000);
        
        if (referralBalance[msg.sender] == 5) {
            totalReferralRewards = totalReferralRewards.add(1);
        }
        
        referralBalance[msg.sender] = referralBalance[msg.sender].add(_incomingEther);
        
        uint256 _devFee = (_incomingEther.mul(devFee)) / 100;
        uint256 _referralFee = (_incomingEther.mul(referralFee)) / 100;
        
        payOut(_referralFee, owner);
        
        uint256 _tokensBought = buyTokens(_incomingEther - _devFee - _referralFee, _customerAddress);
        
        contractValue = contractValue.add(_incomingEther);
        
        if (tokenSupply > magnitude) {
            tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
        }
        
        return _tokensBought;
    }
    
    function sell(uint256 _amountOfTokens) public isActive hasTokens {
        address _customerAddress = msg.sender;
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        require(_amountOfTokens <= _balance);
        
        uint256 _etherValue = (_amountOfTokens.mul(tokenPrice)) / magnitude;
        uint256 _devFee = (_etherValue.mul(devFee)) / 100;
        uint256 _referralFee = (_etherValue.mul(referralFee)) / 100;
        
        tokenSupply = tokenSupply.sub(_amountOfTokens);
        _balance = _balance.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = _balance;
        
        payOut(_referralFee, owner);
        
        _etherValue = _etherValue - _devFee - _referralFee;
        contractValue = contractValue.sub(_etherValue);
        
        if (tokenSupply > magnitude) {
            tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
        }
        
        emit onSellEvent(_customerAddress, _amountOfTokens);
        _customerAddress.transfer(_etherValue);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) public onlyPlayers returns(uint256) {
        require(_amountOfTokens > 5 && _amountOfTokens < tokenSupply);
        
        address _customerAddress = msg.sender;
        uint256 _tokenBalance = tokenBalanceLedger[_customerAddress];
        uint256 _tokensBought = (_amountOfTokens.mul(magnitude)) / tokenPrice;
        require(_tokensBought <= _tokenBalance);
        
        _etherValue = (_tokensBought.mul(tokenPrice)) / magnitude;
        _balance = _balance.sub(_amountOfTokens);
        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_amountOfTokens);
        contractValue = contractValue.sub(_etherValue);
        
        if (tokenSupply > magnitude) {
            tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
        }
        
        _toAddress.transfer(_etherValue);
        return _etherValue;
    }
    
    function donate() public payable onlyPlayers {
        uint256 _incomingEther = msg.value;
        contractValue = contractValue.add(_incomingEther);
        totalDonations = totalDonations.add(_incomingEther);
        
        if (tokenSupply > magnitude) {
            tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _tokens) private returns(bool) {
        require(_tokens <= tokenBalanceLedger[_from]);
        
        if (_tokens > 5) {
            uint256 _taxedTokens = (_tokens.mul(referralFee)) / 100;
            tokenBalanceLedger[_from] = tokenBalanceLedger[_from].sub(_tokens);
            tokenBalanceLedger[_to] = tokenBalanceLedger[_to].add(_tokens - _taxedTokens);
            tokenSupply = tokenSupply.sub(_taxedTokens);
            
            if (tokenSupply > magnitude) {
                tokenPrice = (contractValue.mul(magnitude)) / tokenSupply;
            }
        }
        
        emit Transfer(_from, _to, _tokens);
        return true;
    }
    
    function transfer(address _to, uint256 _tokens) public returns(bool) {
        return transferFrom(msg.sender, _to, _tokens);
    }
    
    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function totalContractValue() public view returns(uint) {
        return contractValue;
    }
    
    function totalReferralRewards() public view returns(uint256) {
        return totalReferralRewards;
    }
    
    function totalDonations() public view returns(uint256) {
        return totalDonations;
    }
    
    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }
    
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger[_customerAddress];
    }
    
    function dividendsOf(bool _includeReferralBonus) public view returns(uint256) {
        uint256 _devFee = 5;
        uint256 _referralFee = 5;
        
        if (_includeReferralBonus) {
            _devFee = (tokenPrice.mul(devFee)) / 100;
            _referralFee = (tokenPrice.mul(referralFee)) / 100;
        }
        
        return tokenPrice - _devFee - _referralFee;
    }
    
    function sellPrice(bool _includeReferralBonus) view public returns(uint256) {
        uint256 _devFee = 5;
        uint256 _referralFee = 5;
        
        if (_includeReferralBonus) {
            _devFee = (tokenPrice.mul(devFee)) / 100;
            _referralFee = (tokenPrice.mul(referralFee)) / 100;
        }
        
        return tokenPrice + _devFee + _referralFee;
    }
    
    function calculateTokensReceived(uint256 _etherToSpend) public view returns (uint256) {
        uint256 _referralFee = (_etherToSpend.mul(referralFee)) / 100;
        uint256 _devFee = (_etherToSpend.mul(devFee)) / 100;
        uint256 _taxedEther = _etherToSpend - _devFee - _referralFee;
        uint256 _tokensBought = (_taxedEther.mul(magnitude)) / tokenPrice;
        return _tokensBought;
    }
    
    function etherBalance(address _customerAddress) view public returns(uint256) {
        uint256 _dividends = dividendsOf(true);
        uint256 _tokenBalance = tokenBalanceLedger[_customerAddress];
        uint256 _etherValue = (_tokenBalance.mul(_dividends)) / magnitude;
        return _etherValue;
    }
    
    function myEarnings() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return etherBalance(_customerAddress);
    }
    
    function etherBalanceNoBonus(address _customerAddress) view public returns(uint256) {
        uint256 _dividends = dividendsOf(false);
        uint256 _tokenBalance = tokenBalanceLedger[_customerAddress];
        uint256 _etherValue = (_tokenBalance.mul(_dividends)) / magnitude;
        return _etherValue;
    }
    
    function myEarningsNoBonus() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return etherBalanceNoBonus(_customerAddress);
    }
    
    function isPlayer(address _address) public view returns(bool) {
        return players[_address];
    }
    
    function referralBalanceOf() public view returns(uint256) {
        return referralBalance[msg.sender];
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}
```