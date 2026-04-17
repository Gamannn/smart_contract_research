```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
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
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint256 value, uint256 fee);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    function increaseApproval(address spender, uint addedValue) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ArtCoin is StandardToken, Ownable {
    string public constant name = "4ArtCoin";
    string public constant symbol = "4Art";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 4354000000 * (10 ** uint256(decimals));
    
    address private founderAddress1;
    address private founderAddress2;
    address private founderAddress3;
    address private founderAddress4;
    address private founderAddress5;
    address private teamAddress;
    address private adviserAddress;
    address private partnershipAddress;
    address private bountyAddress;
    address private affiliateAddress;
    address private miscAddress;
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    mapping(address => bool) private lockedAccounts;
    
    function ArtCoin() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        founderAddress1 = 0x6c7dd291a92b819f38b86f04681b7aa2b137ca2b;
        founderAddress2 = 0xc5ed5782374fa35f801bf8256a1824bcb408e7de;
        founderAddress3 = 0xd4b7828f404b5c3e5c0f9925611a415ba517de64;
        founderAddress4 = 0x4b5ab188b264a34076020db29ed22c461fe8aaf1;
        founderAddress5 = 0x022d7af8563d1ed17fda09eb4183250a2c410c76;
        teamAddress = 0x2d691f4648f75008090e93a22df695567ddd23ee;
        adviserAddress = 0x14463985f44e1d5b52881b6cc8490b8a78cdbe4d;
        partnershipAddress = 0xd089a083ec814e836ae1fea88cee9f09c316ede5;
        bountyAddress = 0x0a8d4f50f1ab1e2bd47c1f4979ff3a1aa07ebc97;
        affiliateAddress = 0xa27bc3b90b2051379036f2e83e7e2274d936b61a;
        miscAddress = 0xbe7194a70730eba492f5869d0810584beedae943;
        
        balances[founderAddress1] = 1390000000 * (10 ** uint256(decimals));
        balances[founderAddress2] = 27500000 * (10 ** uint256(decimals));
        balances[founderAddress3] = 27500000 * (10 ** uint256(decimals));
        balances[founderAddress4] = 27500000 * (10 ** uint256(decimals));
        balances[founderAddress5] = 27500000 * (10 ** uint256(decimals));
        balances[teamAddress] = 39000000 * (10 ** uint256(decimals));
        balances[adviserAddress] = 39000000 * (10 ** uint256(decimals));
        balances[partnershipAddress] = 39000000 * (10 ** uint256(decimals));
        balances[bountyAddress] = 39000000 * (10 ** uint256(decimals));
        balances[affiliateAddress] = 364000000 * (10 ** uint256(decimals));
        balances[miscAddress] = 100000000 * (10 ** uint256(decimals));
        
        lockedAccounts[founderAddress1] = true;
        lockedAccounts[founderAddress2] = true;
        lockedAccounts[founderAddress3] = true;
        lockedAccounts[founderAddress4] = true;
        lockedAccounts[founderAddress5] = true;
        lockedAccounts[teamAddress] = true;
        lockedAccounts[adviserAddress] = true;
        lockedAccounts[partnershipAddress] = true;
        lockedAccounts[bountyAddress] = true;
        lockedAccounts[affiliateAddress] = true;
        lockedAccounts[miscAddress] = true;
    }
    
    function() public payable {
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public {
        require(now > 1543536000);
        uint256 amount = msg.value.div(buyPrice);
        _transfer(owner, msg.sender, amount);
    }
    
    function sell(uint256 amount) public {
        require(now > 1543536000);
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        
        uint256 requiredBalance = amount.mul(sellPrice);
        require(this.balance >= requiredBalance);
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[owner] = balances[owner].add(amount);
        Transfer(msg.sender, owner, amount);
        msg.sender.transfer(requiredBalance);
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balances[from] >= value);
        require(balances[to].add(value) > balances[to]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public onlyAfterLockup(value, msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public onlyAfterLockup(value, from) returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }
    
    modifier onlyAfterLockup {
        if(msg.sender != owner) {
            require(now > 1533513600);
        }
        _;
    }
    
    modifier onlyAfterLockup(uint256 amount, address sender) {
        if(lockedAccounts[sender]) {
            require(now > 1543536000);
            
            if(now > 1543536000 && now < 1569628800) {
                _checkLockup(amount, 24750000 * (10 ** uint256(decimals)), sender);
            }
            
            if(now > 1569628800 && now < 1601251200) {
                _checkLockup(amount, 13750000 * (10 ** uint256(decimals)), sender);
            }
        }
        
        if(lockedAccounts[sender]) {
            require(now > 1543536000);
            
            if(now > 1543536000 && now < 1569628800) {
                _checkLockup(amount, 33150000 * (10 ** uint256(decimals)), sender);
            }
            
            if(now > 1569628800 && now < 1601251200) {
                _checkLockup(amount, 23400000 * (10 ** uint256(decimals)), sender);
            }
        }
        _;
    }
    
    function _checkLockup(uint256 amount, uint256 limit, address account) internal view returns (bool) {
        uint256 remainingBalance = balances[account].sub(amount);
        require(remainingBalance >= limit);
        return true;
    }
}
```