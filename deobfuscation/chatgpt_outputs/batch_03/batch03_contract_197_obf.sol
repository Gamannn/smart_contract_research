```solidity
pragma solidity ^0.4.19;

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract IotaConnectToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public remaining;
    uint256 public ethRate;
    uint256 public icoTokenPrice;
    uint256 public icoStatus;
    uint256 public amountCollected;
    uint256 public allowTransferToken;
    address public owner;
    address public benAddress;
    address public bkaddress;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex);
    
    function IotaConnectToken() public {
        totalSupply = 20000000000000000000000000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        name = "IotaConnect Token";
        symbol = "IOCT";
        decimals = 18;
        remaining = totalSupply;
        ethRate = 718;
        icoStatus = 1;
        icoTokenPrice = 40;
        benAddress = 0xDB19E35e04D3Ab319b3391755e797000000000000;
        bkaddress = 0x3706eeF0148D9408d89A0E86e091370000000000;
        allowTransferToken = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == bkaddress);
        _;
    }
    
    function () public payable {
        if (remaining > 0 && icoStatus == 1) {
            uint256 finalTokens = (msg.value * ethRate) / icoTokenPrice;
            if (finalTokens < remaining) {
                remaining -= finalTokens;
                amountCollected += msg.value / 10 ** 18;
                _transfer(owner, msg.sender, finalTokens);
                TransferSell(owner, msg.sender, finalTokens, 'Online');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
    function sellOffline(address recAddress, uint256 tokenAmount) public onlyOwner {
        if (remaining > 0) {
            uint256 finalTokens = tokenAmount * (10 ** 18);
            if (finalTokens < remaining) {
                remaining -= finalTokens;
                _transfer(owner, recAddress, finalTokens);
                TransferSell(owner, recAddress, finalTokens, 'Offline');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
    function getEthRate() public onlyOwner constant returns (uint) {
        return ethRate;
    }
    
    function getConBal() public onlyOwner constant returns (uint) {
        return this.balance;
    }
    
    function setEthRate(uint newEthRate) public onlyOwner {
        ethRate = newEthRate;
    }
    
    function getTokenPrice() public onlyOwner constant returns (uint) {
        return icoTokenPrice;
    }
    
    function setTokenPrice(uint newTokenRate) public onlyOwner {
        icoTokenPrice = newTokenRate;
    }
    
    function setTransferStatus(uint status) public onlyOwner {
        allowTransferToken = status;
    }
    
    function changeIcoStatus(uint8 status) public onlyOwner {
        icoStatus = status;
    }
    
    function withdraw(uint amountWith) public onlyOwner {
        require(msg.sender == owner || msg.sender == bkaddress);
        benAddress.transfer(amountWith);
    }
    
    function withdrawAll() public onlyOwner {
        require(msg.sender == owner || msg.sender == bkaddress);
        uint256 amountWith = this.balance - 10000000000000000;
        benAddress.transfer(amountWith);
    }
    
    function mintToken(uint256 tokensToMint) public onlyOwner {
        if (tokensToMint > 0) {
            uint256 totalTokenToMint = tokensToMint * (10 ** 18);
            balanceOf[owner] += totalTokenToMint;
            totalSupply += totalTokenToMint;
            Transfer(0, owner, totalTokenToMint);
        }
    }
    
    function freezeAccount(address target, bool freeze) private onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function getCollectedAmount() public onlyOwner constant returns (uint256) {
        return amountCollected;
    }
    
    function balanceOf(address _owner) public constant returns (uint256) {
        return balanceOf[_owner];
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        balanceOf[owner] = 0;
        balanceOf[newOwner] = totalSupply;
        owner = newOwner;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(allowTransferToken == 1 || _from == owner);
        require(!frozenAccount[_from]);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}
```