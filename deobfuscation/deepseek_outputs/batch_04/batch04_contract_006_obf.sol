pragma solidity ^0.4.20;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract EthereumCashPro {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public remainingTokens;
    uint256 public icoTokenPrice;
    uint256 public amountCollected;
    uint256 public allowTransferToken;
    address public owner;
    address public backupAddress;
    address public walletAddress;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string details);

    modifier onlyOwner() {
        require((msg.sender == owner) || (msg.sender == backupAddress));
        _;
    }

    function EthereumCashPro() public {
        totalSupply = 200000000000000000000000000000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        name = "Ethereum Cash Pro";
        symbol = "ECP";
        decimals = 18;
        remainingTokens = totalSupply;
        icoTokenPrice = 1100;
        walletAddress = 0x4532828EC057e6cFa04a42b153d74B345084C4C2;
        backupAddress = 0x1D38b496176bDaB78D430cebf25B2Fe413d3BF84;
        amountCollected = 0;
        allowTransferToken = 0;
    }

    function () public payable {}

    function sellOffline(address _to, uint256 _tokens) public onlyOwner {
        if (remainingTokens > 0) {
            uint256 finalTokens = (_tokens * (10 ** 18));
            if (finalTokens < remainingTokens) {
                remainingTokens = remainingTokens - finalTokens;
                _transfer(owner, _to, finalTokens);
                TransferSell(owner, _to, finalTokens, 'Offline');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function getIcoTokenPrice() onlyOwner public constant returns (uint) {
        return icoTokenPrice;
    }

    function getAmountCollected() onlyOwner public constant returns (uint) {
        return this.balance;
    }

    function setIcoTokenPrice(uint _newPrice) public onlyOwner {
        icoTokenPrice = _newPrice;
    }

    function getTokenPrice() onlyOwner public constant returns (uint) {
        return icoTokenPrice;
    }

    function setTokenPrice(uint _newPrice) public onlyOwner {
        icoTokenPrice = _newPrice;
    }

    function setAllowTransferToken(uint _allow) public onlyOwner {
        allowTransferToken = _allow;
    }

    function setIcoStage(uint8 _stage) public onlyOwner {
        // Stage setting logic
    }

    function withdraw(uint _amount) public onlyOwner {
        if ((msg.sender == owner) || (msg.sender == backupAddress)) {
            walletAddress.transfer(_amount);
        } else {
            revert();
        }
    }

    function withdrawAll() public onlyOwner {
        if ((msg.sender == owner) || (msg.sender == backupAddress)) {
            uint amount = this.balance - 10000000000000000;
            walletAddress.transfer(amount);
        } else {
            revert();
        }
    }

    function mintToken(uint256 _mintedAmount) public onlyOwner {
        if (_mintedAmount > 0) {
            uint256 tokensToMint = _mintedAmount * (10 ** 18);
            balanceOf[owner] += tokensToMint;
            totalSupply += tokensToMint;
            Transfer(0, owner, tokensToMint);
        }
    }

    function transferFromOwner(address _from, address _to, uint256 _value) public onlyOwner {
        _transfer(_from, _to, _value);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function getBalance() onlyOwner public constant returns (uint256) {
        return this.balance;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balanceOf[_owner];
    }

    function totalSupply() private constant returns (uint256) {
        return totalSupply;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        balanceOf[owner] = 0;
        balanceOf[newOwner] = remainingTokens;
        owner = newOwner;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        if (allowTransferToken == 1 || _from == owner) {
            require(!frozenAccount[_from]);
            require(_to != 0x0);
            require(balanceOf[_from] > _value);
            require(balanceOf[_to] + _value > balanceOf[_to]);
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            Transfer(_from, _to, _value);
        } else {
            revert();
        }
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value < allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] > _value);
        balanceOf[msg.sender] -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Burn(_from, _value);
        return true;
    }
}