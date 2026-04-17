```solidity
pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract ERC20Token {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    bool public transferable;
    
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    function balanceOf(address who) view public returns(uint256) {
        return balances[who];
    }
    
    function allowance(address owner, address spender) view public returns(uint256) {
        return allowed[owner][spender];
    }
    
    function _transfer(address from, address to, uint value) internal {
        require(transferable);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns(bool) {
        TokenRecipient tokenRecipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            tokenRecipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
        return false;
    }
    
    function burn(uint256 value) public returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }
    
    function burnFrom(address from, uint256 value) public returns(bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(from, value);
        return true;
    }
}

contract AigathaToken is ERC20Token, Ownable {
    using SafeMath for uint256;
    
    string public constant name = "AIgatha Token";
    string public constant symbol = "ATH";
    uint8 public constant decimals = 18;
    
    uint256 public startDate;
    uint256 public endDate;
    uint256 public saleCap;
    uint256 public threshold;
    uint256 public weiRaised;
    address public wallet;
    bool public extended;
    
    uint256 public constant TOTAL_SUPPLY = 48879 * (10 ** uint256(decimals));
    uint256 public constant SALE_CAP = 1296000 * (10 ** uint256(decimals));
    
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event PreICOTokenPushed(address indexed beneficiary, uint256 amount);
    
    function AigathaToken() public {
        totalSupply = TOTAL_SUPPLY;
        saleCap = SALE_CAP;
        startDate = 1525132800;
        endDate = 1530316800;
        threshold = 5184000;
        wallet = 0xbeef;
        balances[wallet] = balances[wallet].add(totalSupply.sub(saleCap));
        balances[address(this)] = saleCap;
        transferable = false;
        owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function saleActive() public view returns (bool) {
        return now >= startDate && now <= endDate && balances[address(this)] > 0;
    }
    
    function extendSale() onlyOwner public {
        require(!saleActive());
        require(!extended);
        require((saleCap - tokensSold()) < threshold);
        extended = true;
        endDate += 60 days;
    }
    
    function getRate(uint256 purchaseDate) public view returns(uint256) {
        if (purchaseDate < startDate) {
            return 0;
        } else if (purchaseDate < (startDate + 15 days)) {
            return 10500;
        } else {
            return 10000;
        }
    }
    
    function () payable public {
        buyTokens(msg.sender, msg.value);
    }
    
    function pushPreICO(address beneficiary, uint256 amount) onlyOwner public {
        require(balances[wallet] >= amount);
        balances[wallet] = balances[wallet].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit PreICOTokenPushed(beneficiary, amount);
    }
    
    function buyTokens(address sender, uint256 weiAmount) internal {
        require(saleActive());
        uint256 refund = weiAmount;
        uint256 weiTotal = weiRaised.add(weiAmount);
        uint256 rate = getRate(now);
        uint256 tokens = weiAmount.mul(rate);
        require(tokensSold() >= tokens);
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[sender] = balances[sender].add(tokens);
        emit TokenPurchase(sender, weiAmount, tokens);
        weiRaised = weiTotal;
    }
    
    function tokensSold() public view returns(uint256) {
        return saleCap.sub(balances[address(this)]);
    }
    
    function withdraw() onlyOwner public {
        wallet.transfer(address(this).balance);
    }
    
    function finalize() onlyOwner public {
        require(!saleActive());
        balances[wallet] = balances[wallet].add(balances[address(this)]);
        balances[address(this)] = 0;
        transferable = true;
    }
}
```