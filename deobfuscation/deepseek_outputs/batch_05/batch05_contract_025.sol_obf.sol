```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    address public newOwner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract ERC20Interface {
    string public constant name = "FIRST DRIVER";
    string public constant symbol = "DRIVER";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    
    function balanceOf(address _owner) public constant returns (uint256) {
        return balanceOf[_owner];
    }
    
    function approve(address _spender, uint256 _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowance[_owner][_spender];
    }
    
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract Token is Ownable, ERC20Interface {
    using SafeMath for uint256;
    
    uint256 internal bankBalance = 0;
    uint256 public price = 800000000;
    uint256 internal constant PRICE_DENOMINATOR = 10000000;
    uint256 internal constant MIN_BUY = 1000000000000000;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed buyer, uint256 amount, uint256 tokens);
    
    constructor() public payable {
        totalSupply = 0;
        price = 800000000;
    }
    
    function() public payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _buyer) internal {
        require(msg.value >= MIN_BUY);
        mintTokens(_buyer, msg.value);
    }
    
    function mintTokens(address _buyer, uint256 _value) internal {
        uint256 tokens = _value.div(price.mul(10).div(8));
        require(tokens > 0);
        require(balanceOf[_buyer].add(tokens) > balanceOf[_buyer]);
        
        totalSupply = totalSupply.add(tokens);
        balanceOf[_buyer] = balanceOf[_buyer].add(tokens);
        
        uint256 fee = _value.div(100);
        bankBalance = bankBalance.add(fee);
        
        price = bankBalance.div(totalSupply);
        
        uint256 change = _value % (price.mul(10).div(8));
        require(change > 0);
        
        emit Buy(_buyer, _value, tokens);
        emit Transfer(address(0), _buyer, tokens);
        
        _value = 0;
        tokens = 0;
        
        owner.transfer(fee.mul(5));
        address(0x476371DD2bB73e800631F5Acfea5b5c0178aA605).transfer(fee.mul(5));
        _buyer.transfer(change);
        change = 0;
    }
    
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        if(_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            uint256 refund = _value.mul(price);
            require(address(this).balance >= refund);
            
            if(totalSupply > _value) {
                uint256 tokenValue = (address(this).balance.sub(bankBalance)).div(totalSupply);
                bankBalance = bankBalance.sub(refund);
                totalSupply = totalSupply.sub(_value);
                bankBalance = bankBalance.add(tokenValue.mul(_value));
                price = bankBalance.div(totalSupply);
                emit Transfer(msg.sender, _to, _value);
                allowance[msg.sender][msg.sender] = allowance[msg.sender][msg.sender].sub(_value);
            }
            
            if(totalSupply == _value) {
                price = address(this).balance.div(totalSupply);
                price = price.mul(101).div(100);
                totalSupply = 0;
                bankBalance = 0;
                emit Transfer(msg.sender, _to, _value);
                allowance[msg.sender][msg.sender] = allowance[msg.sender][msg.sender].sub(_value);
                owner.transfer(address(this).balance.sub(refund));
            }
            
            msg.sender.transfer(refund);
        }
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        
        if(_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        } else {
            balanceOf[_from] = balanceOf[_from].sub(_value);
            uint256 refund = _value.mul(price);
            require(address(this).balance >= refund);
            
            if(totalSupply > _value) {
                uint256 tokenValue = (address(this).balance.sub(bankBalance)).div(totalSupply);
                bankBalance = bankBalance.sub(refund);
                totalSupply = totalSupply.sub(_value);
                bankBalance = bankBalance.add(tokenValue.mul(_value));
                price = bankBalance.div(totalSupply);
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            }
            
            if(totalSupply == _value) {
                price = address(this).balance.div(totalSupply);
                price = price.mul(101).div(100);
                totalSupply = 0;
                bankBalance = 0;
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
                owner.transfer(address(this).balance.sub(refund));
            }
            
            _from.transfer(refund);
        }
        
        return true;
    }
}
```