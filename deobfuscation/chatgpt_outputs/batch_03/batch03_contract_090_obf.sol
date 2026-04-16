pragma solidity ^0.4.17;

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract ElevateCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public remaining;
    uint256 public ethRate;
    uint256 public icoTokenPrice;
    uint256 public icoStatus;
    uint256 public amountCollected;
    address public owner;
    address public benAddress;
    address public bkaddress;
    uint256 public allowTransferToken;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex);
    
    function ElevateCoin() public {
        totalSupply = 10000000000000000000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        name = "Elevate Coin";
        symbol = "ElevateCoin";
        decimals = 18;
        remaining = totalSupply;
        ethRate = 300;
        icoStatus = 1;
        icoTokenPrice = 10;
        benAddress = 0x57D1aED65eE1921CC7D2F3702C8A23;
        bkaddress = 0xE254FC78C94D7A358F78323E56D9BB3;
        allowTransferToken = 0;
    }
    
    modifier onlyOwnerOrBkaddress() {
        require((msg.sender == owner) || (msg.sender == bkaddress));
        _;
    }
    
    function () public payable {
        if (remaining > 0 && icoStatus == 1) {
            uint256 finalTokens = (msg.value * ethRate) / icoTokenPrice;
            if (finalTokens < remaining) {
                remaining -= finalTokens;
                amountCollected += (msg.value / 10 ** 18);
                _transfer(owner, msg.sender, finalTokens);
                TransferSell(owner, msg.sender, finalTokens, 'Online');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
    function sellOffline(address recAddress, uint256 tokenAmount) public onlyOwnerOrBkaddress {
        if (remaining > 0) {
            uint256 finalTokens = tokenAmount * (10 ** decimals);
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
    
    function getEthRate() public view onlyOwnerOrBkaddress returns (uint) {
        return ethRate;
    }
    
    function setEthRate(uint newEthRate) public onlyOwnerOrBkaddress {
        ethRate = newEthRate;
    }
    
    function getTokenPrice() public view onlyOwnerOrBkaddress returns (uint) {
        return icoTokenPrice;
    }
    
    function setTokenPrice(uint newTokenRate) public onlyOwnerOrBkaddress {
        icoTokenPrice = newTokenRate;
    }
    
    function setTransferStatus(uint status) public onlyOwnerOrBkaddress {
        allowTransferToken = status;
    }
    
    function changeIcoStatus(uint8 status) public onlyOwnerOrBkaddress {
        icoStatus = status;
    }
    
    function withdraw(uint amount) public onlyOwnerOrBkaddress {
        benAddress.transfer(amount);
    }
    
    function withdrawAll() public onlyOwnerOrBkaddress {
        uint256 amount = this.balance - 10000000000000000;
        benAddress.transfer(amount);
    }
    
    function mintToken(uint256 tokensToMint) public onlyOwnerOrBkaddress {
        if (tokensToMint > 0) {
            uint256 totalTokenToMint = tokensToMint * (10 ** decimals);
            balanceOf[owner] += totalTokenToMint;
            totalSupply += totalTokenToMint;
            Transfer(0, owner, totalTokenToMint);
        }
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwnerOrBkaddress {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function getCollectedAmount() public view onlyOwnerOrBkaddress returns (uint256) {
        return amountCollected;
    }
    
    function transferOwnership(address newOwner) public onlyOwnerOrBkaddress {
        balanceOf[owner] = 0;
        balanceOf[newOwner] = remaining;
        owner = newOwner;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(allowTransferToken == 1 || _from == owner);
        require(!frozenAccount[_from]);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
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