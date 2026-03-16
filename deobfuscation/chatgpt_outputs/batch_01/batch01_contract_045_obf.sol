```solidity
pragma solidity ^0.4.25;

interface HDX20Interface {
    function moveAccountIn(address _customerAddress) payable external;
}

contract HDX20 {
    using SafeMath for uint256;

    HDX20Interface private newHDX20Contract = HDX20Interface(0);

    event OwnershipTransferred(address indexed previousOwner, address indexed nextOwner);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event onBuyEvent(address from, uint256 tokens);
    event onSellEvent(address from, uint256 tokens);
    event onAccountMovedOut(address indexed from, address to, uint256 tokens, uint256 eth);
    event onAccountMovedIn(address indexed from, address to, uint256 tokens, uint256 eth);
    event HDXcontractChanged(address previous, address next, uint256 timeStamp);

    modifier onlyOwner {
        require(msg.sender == contractData.owner);
        _;
    }

    modifier onlyFromGameWhiteListed {
        require(gameWhiteListed[msg.sender] == true);
        _;
    }

    modifier onlyGameWhiteListed(address who) {
        require(gameWhiteListed[who] == true);
        _;
    }

    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    constructor() public {
        contractData.owner = msg.sender;
        if (address(this).balance > 0) {
            contractData.owner.transfer(address(this).balance);
        }
    }

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => bool) private gameWhiteListed;
    mapping(address => uint8) private superReferrerRate;

    function() payable public {
        buyToken(address(0));
    }

    function changeOwner(address _nextOwner) public onlyOwner {
        require(_nextOwner != contractData.owner);
        require(_nextOwner != address(0));
        emit OwnershipTransferred(contractData.owner, _nextOwner);
        contractData.owner = _nextOwner;
    }

    function changeName(string _name) public onlyOwner {
        contractData.name = _name;
    }

    function changeSymbol(string _symbol) public onlyOwner {
        contractData.symbol = _symbol;
    }

    function addGame(address _contractAddress) public onlyOwner {
        gameWhiteListed[_contractAddress] = true;
    }

    function addSuperReferrer(address _contractAddress, uint8 extra_rate) public onlyOwner {
        superReferrerRate[_contractAddress] = extra_rate;
    }

    function removeGame(address _contractAddress) public onlyOwner {
        gameWhiteListed[_contractAddress] = false;
    }

    function changeNewHDX20Contract(address _next) public onlyOwner {
        require(_next != address(newHDX20Contract));
        require(_next != address(0));
        emit HDXcontractChanged(address(newHDX20Contract), _next, now);
        newHDX20Contract = HDX20Interface(_next);
    }

    function buyTokenSub(uint256 _eth, address _customerAddress) private returns (uint256) {
        uint256 _nb_token = (_eth.mul(contractData.magnitude)) / contractData.tokenPrice;
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].add(_nb_token);
        contractData.tokenSupply = contractData.tokenSupply.add(_nb_token);
        emit onBuyEvent(_customerAddress, _nb_token);
        return (_nb_token);
    }

    function buyTokenFromGame(address _customerAddress, address _referrer_address) public payable onlyFromGameWhiteListed returns (uint256) {
        uint256 _eth = msg.value;
        if (_eth == 0) return (0);
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        uint256 _fee = (_eth.mul(contractData.buyInFee)) / 100;
        if (_referrer_address != address(0) && _referrer_address != _customerAddress) {
            uint256 _ethReferrer = (_fee.mul(contractData.referrerFee + superReferrerRate[_referrer_address])) / 100;
            buyTokenSub(_ethReferrer, _referrer_address);
            _fee = _fee.sub(_ethReferrer);
        }
        buyTokenSub((_devfee.mul(100 - contractData.buyInFee)) / 100, contractData.owner);
        uint256 _nb_token = buyTokenSub(_eth - _fee - _devfee, _customerAddress);
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        return (_nb_token);
    }

    function buyToken(address _referrer_address) public payable returns (uint256) {
        uint256 _eth = msg.value;
        address _customerAddress = msg.sender;
        require(_eth > 0);
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        uint256 _fee = (_eth.mul(contractData.buyInFee)) / 100;
        if (_referrer_address != address(0) && _referrer_address != _customerAddress) {
            uint256 _ethReferrer = (_fee.mul(contractData.referrerFee + superReferrerRate[_referrer_address])) / 100;
            buyTokenSub(_ethReferrer, _referrer_address);
            _fee = _fee.sub(_ethReferrer);
        }
        buyTokenSub((_devfee.mul(100 - contractData.buyInFee)) / 100, contractData.owner);
        uint256 _nb_token = buyTokenSub(_eth - _fee - _devfee, _customerAddress);
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        return (_nb_token);
    }

    function sellToken(uint256 _amountOfTokens) public onlyTokenHolders {
        address _customerAddress = msg.sender;
        uint256 balance = tokenBalanceLedger[_customerAddress];
        require(_amountOfTokens <= balance);
        uint256 _eth = (_amountOfTokens.mul(contractData.tokenPrice)) / contractData.magnitude;
        uint256 _fee = (_eth.mul(contractData.sellOutFee)) / 100;
        uint256 _devfee = (_eth.mul(contractData.devFee)) / 100;
        contractData.tokenSupply = contractData.tokenSupply.sub(_amountOfTokens);
        balance = balance.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = balance;
        buyTokenSub((_devfee.mul(100 - contractData.buyInFee)) / 100, contractData.owner);
        _eth = _eth - _fee - _devfee;
        contractData.contractValue = contractData.contractValue.sub(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        emit onSellEvent(_customerAddress, _amountOfTokens);
        _customerAddress.transfer(_eth);
    }

    function payWithToken(uint256 _eth, address _player_address) public onlyFromGameWhiteListed returns (uint256) {
        require(_eth > 0 && _eth <= ethBalanceOfNoFee(_player_address));
        address _game_contract = msg.sender;
        uint256 balance = tokenBalanceLedger[_player_address];
        uint256 _nb_token = (_eth.mul(contractData.magnitude)) / contractData.tokenPrice;
        require(_nb_token <= balance);
        _eth = (_nb_token.mul(contractData.tokenPrice)) / contractData.magnitude;
        balance = balance.sub(_nb_token);
        contractData.tokenSupply = contractData.tokenSupply.sub(_nb_token);
        tokenBalanceLedger[_player_address] = balance;
        contractData.contractValue = contractData.contractValue.sub(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        _game_contract.transfer(_eth);
        return (_eth);
    }

    function moveAccountOut() public onlyTokenHolders {
        address _customerAddress = msg.sender;
        require(ethBalanceOfNoFee(_customerAddress) > 0 && address(newHDX20Contract) != address(0));
        uint256 balance = tokenBalanceLedger[_customerAddress];
        uint256 _eth = (balance.mul(contractData.tokenPrice)) / contractData.magnitude;
        contractData.tokenSupply = contractData.tokenSupply.sub(balance);
        tokenBalanceLedger[_customerAddress] = 0;
        contractData.contractValue = contractData.contractValue.sub(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        emit onAccountMovedOut(_customerAddress, address(newHDX20Contract), balance, _eth);
        newHDX20Contract.moveAccountIn.value(_eth)(_customerAddress);
    }

    function moveAccountIn(address _customerAddress) public payable onlyFromGameWhiteListed {
        uint256 _eth = msg.value;
        uint256 _nb_token = buyTokenSub(_eth, _customerAddress);
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
        emit onAccountMovedIn(msg.sender, _customerAddress, _nb_token, _eth);
    }

    function appreciateTokenPrice() public payable onlyFromGameWhiteListed {
        uint256 _eth = msg.value;
        contractData.contractValue = contractData.contractValue.add(_eth);
        if (contractData.tokenSupply > contractData.magnitude) {
            contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
        }
    }

    function transferSub(address _customerAddress, address _toAddress, uint256 _amountOfTokens) private returns (bool) {
        require(_amountOfTokens <= tokenBalanceLedger[_customerAddress]);
        if (_amountOfTokens > 0) {
            uint256 _token_fee = (_amountOfTokens.mul(contractData.transferFee)) / 100;
            _token_fee /= 2;
            tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
            tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_amountOfTokens - (_token_fee * 2));
            tokenBalanceLedger[contractData.owner] += _token_fee;
            contractData.tokenSupply = contractData.tokenSupply.sub(_token_fee);
            if (contractData.tokenSupply > contractData.magnitude) {
                contractData.tokenPrice = (contractData.contractValue.mul(contractData.magnitude)) / contractData.tokenSupply;
            }
        }
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) public returns (bool) {
        return (transferSub(msg.sender, _toAddress, _amountOfTokens));
    }

    function totalEthereumBalance() public view returns (uint) {
        return address(this).balance;
    }

    function totalContractBalance() public view returns (uint) {
        return contractData.contractValue;
    }

    function totalSupply() public view returns (uint256) {
        return contractData.tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) view public returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function sellingPrice(bool includeFees) view public returns (uint256) {
        uint256 _fee = 0;
        uint256 _devfee = 0;
        if (includeFees) {
            _fee = (contractData.tokenPrice.mul(contractData.sellOutFee)) / 100;
            _devfee = (contractData.tokenPrice.mul(contractData.devFee)) / 100;
        }
        return (contractData.tokenPrice - _fee - _devfee);
    }

    function buyingPrice(bool includeFees) view public returns (uint256) {
        uint256 _fee = 0;
        uint256 _devfee = 0;
        if (includeFees) {
            _fee = (contractData.tokenPrice.mul(contractData.buyInFee)) / 100;
            _devfee = (contractData.tokenPrice.mul(contractData.devFee)) / 100;
        }
        return (contractData.tokenPrice + _fee + _devfee);
    }

    function ethBalanceOf(address _customerAddress) view public returns (uint256) {
        uint256 _price = sellingPrice(true);
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        uint256 _ethBalance = (_balance.mul(_price)) / contractData.magnitude;
        return (_ethBalance);
    }

    function myEthBalanceOf() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return ethBalanceOf(_customerAddress);
    }

    function ethBalanceOfNoFee(address _customerAddress) view public returns (uint256) {
        uint256 _price = sellingPrice(false);
        uint256 _balance = tokenBalanceLedger[_customerAddress];
        uint256 _ethBalance = (_balance.mul(_price)) / contractData.magnitude;
        return (_ethBalance);
    }

    function myEthBalanceOfNoFee() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return ethBalanceOfNoFee(_customerAddress);
    }

    function checkGameListed(address _contract) view public returns (bool) {
        return (gameWhiteListed[_contract]);
    }

    function getSuperReferrerRate(address _customerAddress) view public returns (uint8) {
        return (contractData.referrerFee + superReferrerRate[_customerAddress]);
    }

    struct ContractData {
        uint256 tokenPrice;
        uint256 contractValue;
        uint256 tokenSupply;
        uint8 devFee;
        uint8 sellOutFee;
        uint8 buyInFee;
        uint8 transferFee;
        uint8 referrerFee;
        uint256 magnitude;
        uint8 decimals;
        string symbol;
        string name;
        address owner;
    }

    ContractData contractData = ContractData(
        0.001 ether,
        0,
        0,
        1,
        3,
        3,
        2,
        50,
        1e18,
        18,
        "HDX20",
        "HDX20 token",
        address(0)
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
```