pragma solidity ^0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = 0x858A045e0559ffCc1bB0bB394774CF49b02593F0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract PaysCommission {
    address public commissionGetter;
    uint256 public minimumEtherCommission;
    uint256 public minimumTokenCommission;

    constructor() public {
        commissionGetter = 0xCd8bf69ad65c5158F0cfAA599bBF90d7f4b52Bb0;
        minimumEtherCommission = 50000000000;
        minimumTokenCommission = 1;
    }

    modifier onlyCommissionGetter {
        require(msg.sender == commissionGetter);
        _;
    }

    function transferCommissionGetter(address newCommissionGetter) public onlyCommissionGetter {
        commissionGetter = newCommissionGetter;
    }

    function changeMinimumCommission(uint256 newMinEtherCommission, uint newMinTokenCommission) public onlyCommissionGetter {
        minimumEtherCommission = newMinEtherCommission;
        minimumTokenCommission = newMinTokenCommission;
    }
}

contract SMBQToken is PaysCommission, Owned {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);

    struct TokenDetails {
        bool closeSell;
        uint256 sellPrice;
        uint256 buyPrice;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
    }

    TokenDetails public tokenDetails;

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        tokenDetails.totalSupply = initialSupply * 10 ** uint256(tokenDetails.decimals);
        balanceOf[owner] = tokenDetails.totalSupply;
        tokenDetails.name = tokenName;
        tokenDetails.symbol = tokenSymbol;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    function _payTokenCommission(uint256 value) internal {
        uint marketValue = value * tokenDetails.sellPrice;
        uint commissionValue = marketValue / 100;
        uint commission = commissionValue / tokenDetails.sellPrice;

        if (commission < minimumTokenCommission) {
            commission = minimumTokenCommission;
        }

        _transfer(this, commissionGetter, commission);
    }

    function refillTokens(uint256 value) public onlyOwner {
        _transfer(msg.sender, this, value);
    }

    function mintToken(uint256 mintedAmount) public onlyOwner {
        balanceOf[owner] += mintedAmount;
        tokenDetails.totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, owner, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        tokenDetails.sellPrice = newSellPrice;
        tokenDetails.buyPrice = newBuyPrice;
    }

    function setStatus(bool isClosedSell) public onlyOwner {
        tokenDetails.closeSell = isClosedSell;
    }

    function withdrawEther(uint amountInWeis) public onlyOwner {
        require(address(this).balance >= amountInWeis);
        emit Withdrawal(msg.sender, amountInWeis);
        owner.transfer(amountInWeis);
    }

    function transfer(address to, uint256 value) public {
        _payTokenCommission(value);
        _transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        _payTokenCommission(value);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function depositEther() public payable returns (bool success) {
        require(address(this).balance + msg.value > address(this).balance);
        emit Deposit(msg.sender, msg.value);
        return true;
    }

    function buy() public payable {
        uint amount = msg.value / tokenDetails.buyPrice;
        uint marketValue = amount * tokenDetails.buyPrice;
        uint commission = marketValue / 100;

        if (commission < minimumEtherCommission) {
            commission = minimumEtherCommission;
        }

        require(address(this).balance >= commission);
        commissionGetter.transfer(commission);
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(!tokenDetails.closeSell);
        _payTokenCommission(amount);
        _transfer(msg.sender, this, amount);
        uint marketValue = amount * tokenDetails.sellPrice;
        require(address(this).balance >= marketValue);
        msg.sender.transfer(marketValue);
    }

    function() public payable {
        buy();
    }
}