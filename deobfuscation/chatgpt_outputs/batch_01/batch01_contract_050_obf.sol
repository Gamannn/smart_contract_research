pragma solidity ^0.4.26;

contract EtherCenter {
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[keccak256(abi.encodePacked(_customerAddress))]);
        _;
    }

    modifier onlyValidAddress(address _to) {
        require(_to != address(0x0000000000000000000000000000000000000000));
        _;
    }

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal payoutsTo_;
    mapping(bytes32 => bool) public administrators;

    struct Scalar2Vector {
        uint256 ethereumBuy_;
        uint256 tokenSupply_;
        address admin_;
        uint256 defaultValue;
        uint256 tokenPriceInitial_;
        uint8 valueChange_;
        uint8 realRate_;
        uint8 decimals;
        string symbol;
        string name;
    }

    Scalar2Vector internal settings = Scalar2Vector(
        0,
        0,
        address(0xaD5874D6A14CC9963FC303F745f454Ef3A6E9BEb),
        10**18,
        0.001 ether,
        5,
        98,
        18,
        "EC",
        "EtherCenter"
    );

    constructor() public {
        administrators[keccak256(abi.encode(settings.admin_))] = true;
    }

    function buy() public payable {
        settings.ethereumBuy_ = msg.value;
        purchaseTokens(msg.value);
        settings.ethereumBuy_ = 0;
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders() public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _realEthereum = SafeMath.div(SafeMath.mul(_ethereum, settings.realRate_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _realEthereum);
        settings.tokenSupply_ = SafeMath.sub(settings.tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        _customerAddress.transfer(_realEthereum);
        settings.admin_.transfer(_taxedEthereum);
        emit onTokenSell(_customerAddress, _tokens, _realEthereum);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyValidAddress(_toAddress) onlyBagholders() public returns (bool) {
        address _customerAddress = msg.sender;
        uint256 _taxedTokens = SafeMath.div(SafeMath.mul(_amountOfTokens, settings.valueChange_), 100);
        require(SafeMath.sub(_amountOfTokens, _taxedTokens) <= tokenBalanceLedger_[_customerAddress]);
        uint256 _realTokens = SafeMath.sub(_amountOfTokens, _taxedTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _realTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        settings.tokenSupply_ -= _taxedTokens;
        emit Transfer(_customerAddress, _toAddress, _realTokens);
        return true;
    }

    function setAdministrator(bytes32 _identifier, bool _status) onlyAdministrator() public {
        administrators[_identifier] = _status;
    }

    function setName(string memory _name) onlyAdministrator() public {
        settings.name = _name;
    }

    function setSymbol(string memory _symbol) onlyAdministrator() public {
        settings.symbol = _symbol;
    }

    function totalEthereumBalance() public view returns (uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return settings.tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) view public returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function sellPrice() public view returns (uint256) {
        uint256 _ethereum = guaranteePrice_();
        uint256 _sellEthereum = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(_ethereum, SafeMath.sub(100, settings.valueChange_)), 100), settings.realRate_), 100);
        return _sellEthereum;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _ethereum = guaranteePrice_();
        uint256 _buyEthereum = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(_ethereum, SafeMath.add(100, settings.valueChange_)), 100), settings.realRate_), 100);
        return _buyEthereum;
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _amountOfTokens = ethereumToTokens_(_ethereumToSpend);
        uint256 _realTokens = SafeMath.div(SafeMath.mul(_amountOfTokens, settings.realRate_), 100);
        return _realTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= settings.tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _realEthereum = SafeMath.div(SafeMath.mul(_ethereum, settings.realRate_), 100);
        return _realEthereum;
    }

    function purchaseTokens(uint256 _incomingEthereum) internal {
        address _customerAddress = msg.sender;
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);
        uint256 _realTokens = SafeMath.div(SafeMath.mul(_amountOfTokens, settings.realRate_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _realTokens);
        require(_realTokens > 0 && _realTokens <= 3000 * settings.defaultValue && (SafeMath.add(_realTokens, settings.tokenSupply_) > settings.tokenSupply_));
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _realTokens);
        tokenBalanceLedger_[settings.admin_] = SafeMath.add(tokenBalanceLedger_[settings.admin_], _taxedTokens);
        settings.tokenSupply_ += _amountOfTokens;
        payoutsTo_[_customerAddress] += SafeMath.div(SafeMath.mul(_realTokens, settings.defaultValue), 100);
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _realTokens);
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _guarantee = guaranteePrice_();
        uint256 _tokensReceived = SafeMath.div(SafeMath.mul(_ethereum * settings.defaultValue, SafeMath.div(SafeMath.mul(_guarantee, SafeMath.sub(100, settings.valueChange_)), 100)), 100);
        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
        uint256 _guarantee = guaranteePrice_();
        uint256 _etherReceived = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(_tokens, SafeMath.div(SafeMath.mul(_guarantee, SafeMath.sub(100, settings.valueChange_)), 100)), 100), settings.defaultValue), 100);
        return _etherReceived;
    }

    function guaranteePrice_() internal view returns (uint256) {
        uint256 _guarantee = 0;
        if (settings.tokenSupply_ == 0) {
            _guarantee = settings.tokenPriceInitial_;
        } else {
            _guarantee = SafeMath.div(SafeMath.mul((address(this).balance - settings.ethereumBuy_) * settings.defaultValue, settings.tokenSupply_), 100);
        }
        return _guarantee;
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
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
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