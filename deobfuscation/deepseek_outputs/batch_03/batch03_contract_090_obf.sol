```solidity
pragma solidity ^0.4.17;

contract tokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract ElevateCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public remaining;
    uint256 public ethRate;
    uint256 public icoStatus;
    uint256 public icoTokenPrice;
    uint256 public amountCollected;
    uint256 public allowTransferToken;
    address public owner;
    address public bkaddress;
    address public benAddress;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex);
    
    modifier onlyOwnerOrBackup() {
        require((msg.sender == owner) || (msg.sender == bkaddress));
        _;
    }
    
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
        benAddress = 0x57D1aED65eE1921CC7D2F3702C8A2;
        bkaddress = 0xE254FC78C94D7A358F78323E56D9BB;
        allowTransferToken = 0;
    }
    
    function () public payable {
        if (remaining > 0 && icoStatus == 1) {
            uint finalTokens = (msg.value * ethRate) / icoTokenPrice;
            finalTokens = finalTokens * (10 ** 18);
            
            if(finalTokens < remaining) {
                remaining = remaining - finalTokens;
                amountCollected = amountCollected + (msg.value / 10 ** 18);
                _transfer(owner, msg.sender, finalTokens);
                TransferSell(owner, msg.sender, finalTokens, 'Online');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
    function sellOffline(address rec_address, uint256 token_amount) public onlyOwnerOrBackup {
        if (remaining > 0) {
            uint finalTokens = (token_amount * (10 ** 18));
            
            if(finalTokens < remaining) {
                remaining = remaining - finalTokens;
                _transfer(owner, rec_address, finalTokens);
                TransferSell(owner, rec_address, finalTokens, 'Offline');
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
    function getEthRate() public onlyOwnerOrBackup constant returns (uint) {
        return ethRate;
    }
    
    function setEthRate(uint newEthRate) public onlyOwnerOrBackup {
        ethRate = newEthRate;
    }
    
    function getTokenPrice() public onlyOwnerOrBackup constant returns (uint) {
        return icoTokenPrice;
    }
    
    function setTokenPrice(uint newTokenRate) public onlyOwnerOrBackup {
        icoTokenPrice = newTokenRate;
    }
    
    function setTransferStatus(uint status) public onlyOwnerOrBackup {
        allowTransferToken = status;
    }
    
    function changeIcoStatus(uint8 statx) public onlyOwnerOrBackup {
        icoStatus = statx;
    }
    
    function withdraw(uint amountWith) public onlyOwnerOrBackup {
        if((msg.sender == owner) || (msg.sender == bkaddress)) {
            benAddress.transfer(amountWith);
        } else {
            revert();
        }
    }
    
    function withdraw_all() public onlyOwnerOrBackup {
        if((msg.sender == owner) || (msg.sender == bkaddress)) {
            uint amountWith = this.balance - 10000000000000000;
            benAddress.transfer(amountWith);
        } else {
            revert();
        }
    }
    
    function mintToken(uint tokensToMint) public onlyOwnerOrBackup {
        if(tokensToMint > 0) {
            uint totalTokenToMint = tokensToMint * (10 ** 18);
            balanceOf[owner] += totalTokenToMint;
            totalSupply += totalTokenToMint;
            Transfer(0, owner, totalTokenToMint);
        }
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwnerOrBackup {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function getCollectedAmount() public onlyOwnerOrBackup constant returns (uint256 balance) {
        return amountCollected;
    }
    
    function totalSupply() private constant returns (uint256 tsupply) {
        tsupply = totalSupply;
    }
    
    function transferOwnership(address newOwner) public onlyOwnerOrBackup {
        balanceOf[owner] = 0;
        balanceOf[newOwner] = remaining;
        owner = newOwner;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        if(allowTransferToken == 1 || _from == owner) {
            require(!frozenAccount[_from]);
            require(_to != 0);
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