pragma solidity ^0.4.26;

contract LuckyCredits {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event onBuyEvent(address buyer, uint256 tokens);
    event onSellEvent(address seller, uint256 tokens);

    modifier isActivated {
        require(contractData.isActive == true || msg.sender == contractData.owner);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == contractData.owner);
        _;
    }

    modifier onlyFromGameWhiteListed {
        require(gameWhiteListed[msg.sender] == true);
        _;
    }

    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    constructor() public {
        contractData.owner = address(0x72bEe2Cf43f658F3EdF5f4E08bAB03b5F777FA0A);
    }

    mapping(address => uint256) public investedETH;
    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => bool) private gameWhiteListed;

    function() payable public {
        appreciateTokenPrice();
    }

    function addGame(address _contractAddress) public onlyOwner {
        gameWhiteListed[_contractAddress] = true;
    }

    function removeGame(address _contractAddress) public onlyOwner {
        gameWhiteListed[_contractAddress] = false;
    }

    function buyTokenSub(uint256 _eth, address _customerAddress) private returns(uint256) {
        uint256 _nb_token = (_eth.mul(contractData.magnitude)) / contractData.tokenPrice;
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].add(_nb_token);
        contractData.tokenSupply = contractData.tokenSupply.add(_nb_token);
        emit onBuyEvent(_customerAddress, _nb_token);
        return _nb_token;
    }

    function buyTokenFromGame(address _customerAddress) public payable onlyFromGameWhiteListed returns(uint256) {
        uint256 _eth = msg.value;
        require(_eth >= 0.0001 ether);
        if (getInvested() == 0) {
            contractData.totalInvestor = contractData.totalInvestor.add(1);
        }
        investedETH[msg.sender] = investedETH[msg.sender].add(_eth);
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        uint256 _fee = (_eth.mul(contractData.buyInFee)) / 100;
        buyTokenSub((_devfee.mul(100 - contractData.buyInFee)) / 100, contractData.owner);
        uint256 _nb_token = buyTokenSub(_eth - _fee - _devfee, _customerAddress);
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        return _nb_token;
    }

    function buyToken() public payable isActivated returns(uint256) {
        if (contractData.isActive == false) {
            contractData.isActive = true;
        }
        uint256 _eth = msg.value;
        address _customerAddress = msg.sender;
        require(_eth >= 0.0001 ether);
        if (getInvested() == 0) {
            contractData.totalInvestor = contractData.totalInvestor.add(1);
        }
        investedETH[msg.sender] = investedETH[msg.sender].add(_eth);
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        uint256 _fee = (_eth.mul(contractData.buyInFee)) / 100;
        buyTokenSub((_devfee.mul(100 - contractData.buyInFee)) / 100, contractData.owner);
        uint256 _nb_token = buyTokenSub(_eth - _fee - _devfee, _customerAddress);
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        return _nb_token;
    }

    function sellToken(uint256 _amountOfTokens) public isActivated onlyTokenHolders {
        address _customerAddress = msg.sender;
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        require(_amountOfTokens <= _balance);
        uint256 _eth = (_amountOfTokens.mul(contractData.tokenPrice)) / contractData.magnitude;
        uint256 _fee = (_eth.mul(contractData.sellOutFee)) / 100;
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        contractData.tokenSupply = contractData.tokenSupply.sub(_amountOfTokens);
        _balance = _balance.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = _balance;
        buyTokenSub((_devfee.mul(100 - contractData.sellOutFee)) / 100, contractData.owner);
        _eth = _eth - _fee - _devfee;
        contractData.contractValue = contractData.contractValue.sub(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        emit onSellEvent(_customerAddress, _amountOfTokens);
        _customerAddress.transfer(_eth);
    }

    function payWithToken(uint256 _eth, address _player_address) public onlyFromGameWhiteListed returns(uint256) {
        require(_eth > 0 && _eth <= ethBalanceOfNoFee(_player_address));
        address _game_contract = msg.sender;
        uint256 _balance = tokenBalanceLedger[_player_address];
        uint256 _nb_token = (_eth.mul(contractData.magnitude)) / contractData.tokenPrice;
        require(_nb_token <= _balance);
        _eth = (_nb_token.mul(contractData.tokenPrice)) / contractData.magnitude;
        _balance = _balance.sub(_nb_token);
        contractData.tokenSupply = contractData.tokenSupply.sub(_nb_token);
        tokenBalanceLedger[_player_address] = _balance;
        contractData.contractValue = contractData.contractValue.sub(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        _game_contract.transfer(_eth);
        return _eth;
    }

    function appreciateTokenPrice() public payable onlyFromGameWhiteListed {
        uint256 _eth = msg.value;
        contractData.contractValue = contractData.contractValue.add(_eth);
        contractData.totalDonation = contractData.totalDonation.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
    }

    function transferSub(address _customerAddress, address _toAddress, uint256 _amountOfTokens) private returns(bool) {
        require(_amountOfTokens <= tokenBalanceLedger[_customerAddress]);
        if (_amountOfTokens > 0) {
            uint256 _token_fee = (_amountOfTokens.mul(contractData.transferFee)) / 100;
            tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
            tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_amountOfTokens - _token_fee);
            contractData.tokenSupply = contractData.tokenSupply.sub(_token_fee);
            if (contractData.tokenSupply > contractData.magnitude) {
                contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
            }
        }
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) public isActivated returns(bool) {
        return transferSub(msg.sender, _toAddress, _amountOfTokens);
    }

    function totalEthereumBalance() public view returns(uint) {
        return address(this).balance;
    }

    function totalContractBalance() public view returns(uint) {
        return contractData.contractValue;
    }

    function totalInvestor() public view returns(uint256) {
        return contractData.totalInvestor;
    }

    function totalDonation() public view returns(uint256) {
        return contractData.totalDonation;
    }

    function totalTokenSupply() public view returns(uint256) {
        return contractData.tokenSupply;
    }

    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function sellingPrice(bool includeFees) view public returns(uint256) {
        uint256 _fee = 0;
        uint256 _devfee = 0;
        if (includeFees) {
            _fee = (contractData.tokenPrice.mul(contractData.sellOutFee)) / 100;
            _devfee = (contractData.tokenPrice.mul(contractData.devFee)) / 100;
        }
        return contractData.tokenPrice - _fee - _devfee;
    }

    function buyingPrice(bool includeFees) view public returns(uint256) {
        uint256 _fee = 0;
        uint256 _devfee = 0;
        if (includeFees) {
            _fee = (contractData.tokenPrice.mul(contractData.buyInFee)) / 100;
            _devfee = (contractData.tokenPrice.mul(contractData.devFee)) / 100;
        }
        return contractData.tokenPrice + _fee + _devfee;
    }

    function calculateTokensReceived(uint256 _eth) public view returns (uint256) {
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        uint256 _fee = (_eth.mul(contractData.buyInFee)) / 100;
        uint256 _taxed_eth = _eth - _fee - _devfee;
        uint256 _nb_token = (_taxed_eth.mul(contractData.magnitude)) / contractData.tokenPrice;
        return _nb_token;
    }

    function ethBalanceOf(address _customerAddress) view public returns(uint256) {
        uint256 _price = sellingPrice(true);
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        uint256 _value = (_balance.mul(_price)) / contractData.magnitude;
        return _value;
    }

    function myEthBalanceOf() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return ethBalanceOf(_customerAddress);
    }

    function ethBalanceOfNoFee(address _customerAddress) view public returns(uint256) {
        uint256 _price = sellingPrice(false);
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        uint256 _value = (_balance.mul(_price)) / contractData.magnitude;
        return _value;
    }

    function myEthBalanceOfNoFee() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return ethBalanceOfNoFee(_customerAddress);
    }

    function checkGameListed(address _contract) public view returns(bool) {
        return gameWhiteListed[_contract];
    }

    function getInvested() public view returns(uint256) {
        return investedETH[msg.sender];
    }

    struct ContractData {
        uint256 tokenPrice;
        uint256 contractValue;
        uint256 tokenSupply;
        uint256 totalDonation;
        uint256 totalInvestor;
        uint8 devFee;
        uint8 sellOutFee;
        uint8 buyInFee;
        uint8 transferFee;
        uint256 magnitude;
        uint8 decimals;
        string symbol;
        string name;
        address owner;
        bool isActive;
    }

    ContractData contractData = ContractData(
        0.001 ether,
        0,
        0,
        0,
        0,
        3,
        7,
        7,
        1,
        1e18,
        18,
        "CREDITS",
        "CREDITS token",
        address(0),
        false
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}