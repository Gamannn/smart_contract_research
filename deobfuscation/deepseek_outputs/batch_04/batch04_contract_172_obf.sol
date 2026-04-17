```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract ERC20 {
    uint256 public totalSupply;
    
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DSBCToken is ERC20, Ownable {
    string public constant name = "dasabi.io DSBC";
    string public constant symbol = "DSBC";
    
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;
    mapping(address => bool) public blacklist;
    
    address public multisigAddress;
    
    event MintToken(address indexed to, uint256 value);
    event BurnToken(address indexed from, uint256 value);
    
    bool public crowdsaleIsOpen = false;
    bool public candyDropIsOpen = false;
    uint256 public candyDropAmount = 50;
    uint256 public exchangeRate = 1000000000;
    uint256 public totalRemainSupply;
    uint256 public totalSupply;
    uint256 public decimalsMultiplier = 10**18;
    uint256 public decimals = 18;
    
    function DSBCToken() public {
        owner = msg.sender;
        totalSupply = 50000 * 10**decimals;
        totalRemainSupply = totalSupply;
        exchangeRate = 1000000000;
        candyDropAmount = 50;
        crowdsaleIsOpen = true;
        candyDropIsOpen = true;
    }
    
    function setExchangeRate(uint256 newExchangeRate) public onlyOwner {
        exchangeRate = newExchangeRate;
    }
    
    function setCandyDropIsOpen(bool isOpen) public onlyOwner {
        candyDropIsOpen = isOpen;
    }
    
    function setCrowdsaleIsOpen(bool isOpen) public onlyOwner {
        crowdsaleIsOpen = isOpen;
    }
    
    function totalRemaining() public constant returns (uint256) {
        return totalSupply - totalRemainSupply;
    }
    
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        require(balances[to] + value > balances[to]);
        
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool) {
        TokenRecipient recipient = TokenRecipient(spender);
        approve(spender, value);
        recipient.receiveApproval(msg.sender, value, this, extraData);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }
    
    function setMultisigAddress(address multisig) public onlyOwner {
        require(multisig != 0x0);
        multisigAddress = multisig;
        transfer(totalSupply);
    }
    
    function mintDSBCToken(address to, uint256 value) public onlyOwner {
        require(balances[to] + value > balances[to]);
        require(totalRemainSupply >= value);
        
        totalRemainSupply -= value;
        balances[to] += value;
        MintToken(to, value);
        Transfer(0x0, to, value);
    }
    
    function mintToken(address to, uint256 value) public onlyOwner {
        mintDSBCToken(to, value);
    }
    
    function burn(uint256 value) public onlyOwner {
        require(balances[msg.sender] >= value);
        totalRemainSupply += value;
        balances[msg.sender] -= value;
        BurnToken(msg.sender, value);
    }
    
    function() payable public {
        require(crowdsaleIsOpen == true);
        
        if (msg.value > 0) {
            mintDSBCToken(msg.sender, msg.value * exchangeRate * decimalsMultiplier / 10**decimals);
        }
        
        if (candyDropIsOpen) {
            if (!blacklist[msg.sender]) {
                mintDSBCToken(msg.sender, candyDropAmount * 10**decimals);
                blacklist[msg.sender] = true;
            }
        }
    }
}
```