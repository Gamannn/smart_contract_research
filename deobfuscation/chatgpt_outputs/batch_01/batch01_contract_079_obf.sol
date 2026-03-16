pragma solidity ^0.4.25;

contract Ownable {
    struct Ownership {
        address owner;
        address newOwner;
    }
    
    Ownership private ownership;
    
    constructor() public payable {
        ownership.owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(ownership.owner == msg.sender);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        ownership.newOwner = _newOwner;
    }
    
    function confirmOwner() public {
        require(ownership.newOwner == msg.sender);
        ownership.owner = ownership.newOwner;
        delete ownership.newOwner;
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

contract ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }
    
    function approve(address _spender, uint256 _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowance[_owner][_spender];
    }
    
    modifier validPayload(uint _size) {
        require(msg.data.length >= _size + 4);
        _;
    }
}

contract NextLevelToken is Ownable, ERC20 {
    using SafeMath for uint256;
    
    struct TokenInfo {
        address ethDriver;
        uint256 maxSupply;
        uint256 minSupply;
        uint256 price;
        uint256 totalSupply;
        uint256 totalRaised;
        uint8 decimals;
        string symbol;
        string name;
    }
    
    TokenInfo private tokenInfo;
    
    constructor() public {
        tokenInfo = TokenInfo(
            0xB453AA2Cdc2F9241d2c451053DA8268B34b4227f,
            10000000000000000000,
            10000000000000000,
            800000000,
            0,
            0,
            6,
            "NLCLUB",
            "NEXT LEVEL CLUB"
        );
    }
    
    function() public payable {
        require(msg.value > 0);
        require(msg.value >= tokenInfo.minSupply);
        require(msg.value <= tokenInfo.maxSupply);
        _processPurchase(msg.sender, msg.value);
    }
    
    function _processPurchase(address _buyer, uint256 _amount) internal {
        uint256 tokens = _amount.div(tokenInfo.price.mul(10).div(8));
        require(tokens > 0);
        require(balanceOf[_buyer].add(tokens) > balanceOf[_buyer]);
        
        tokenInfo.totalSupply = tokenInfo.totalSupply.add(tokens);
        balanceOf[_buyer] = balanceOf[_buyer].add(tokens);
        
        uint256 ethAmount = _amount.div(100);
        tokenInfo.totalRaised = tokenInfo.totalRaised.add(ethAmount.mul(85));
        
        tokenInfo.price = tokenInfo.totalRaised.div(tokenInfo.totalSupply);
        
        uint256 refund = _amount % (tokenInfo.price.mul(10).div(8));
        require(refund > 0);
        
        emit Transfer(this, _buyer, tokens);
        
        _amount = 0;
        tokens = 0;
        
        ownership.owner.transfer(ethAmount.mul(5));
        tokenInfo.ethDriver.transfer(ethAmount.mul(5));
        _buyer.transfer(refund);
        
        refund = 0;
    }
    
    function transfer(address _to, uint256 _value) public validPayload(2 * 32) returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        
        if (_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            uint256 ethAmount = _value.div(tokenInfo.price);
            require(address(this).balance >= ethAmount);
            
            if (tokenInfo.totalSupply > _value) {
                uint256 newPrice = (address(this).balance.sub(tokenInfo.totalRaised)).div(tokenInfo.totalSupply);
                tokenInfo.totalRaised = tokenInfo.totalRaised.sub(ethAmount);
                tokenInfo.totalSupply = tokenInfo.totalSupply.sub(_value);
                tokenInfo.totalRaised = tokenInfo.totalRaised.add(newPrice.mul(_value));
                tokenInfo.price = tokenInfo.totalRaised.div(tokenInfo.totalSupply);
                emit Transfer(msg.sender, _to, _value);
            }
            
            if (tokenInfo.totalSupply == _value) {
                tokenInfo.price = address(this).balance.div(tokenInfo.totalSupply);
                tokenInfo.price = tokenInfo.price.mul(101).div(100);
                tokenInfo.totalSupply = 0;
                tokenInfo.totalRaised = 0;
                emit Transfer(msg.sender, _to, _value);
                ownership.owner.transfer(address(this).balance.sub(ethAmount));
            }
            
            msg.sender.transfer(ethAmount);
        }
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public validPayload(3 * 32) returns (bool) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        
        if (_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        } else {
            balanceOf[_from] = balanceOf[_from].sub(_value);
            uint256 ethAmount = _value.div(tokenInfo.price);
            require(address(this).balance >= ethAmount);
            
            if (tokenInfo.totalSupply > _value) {
                uint256 newPrice = (address(this).balance.sub(tokenInfo.totalRaised)).div(tokenInfo.totalSupply);
                tokenInfo.totalRaised = tokenInfo.totalRaised.sub(ethAmount);
                tokenInfo.totalSupply = tokenInfo.totalSupply.sub(_value);
                tokenInfo.totalRaised = tokenInfo.totalRaised.add(newPrice.mul(_value));
                tokenInfo.price = tokenInfo.totalRaised.div(tokenInfo.totalSupply);
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            }
            
            if (tokenInfo.totalSupply == _value) {
                tokenInfo.price = address(this).balance.div(tokenInfo.totalSupply);
                tokenInfo.price = tokenInfo.price.mul(101).div(100);
                tokenInfo.totalSupply = 0;
                tokenInfo.totalRaised = 0;
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
                ownership.owner.transfer(address(this).balance.sub(ethAmount));
            }
            
            _from.transfer(ethAmount);
        }
        
        return true;
    }
}