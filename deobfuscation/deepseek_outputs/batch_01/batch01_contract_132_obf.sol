pragma solidity ^0.4.25;

contract OWN {
    address public owner;
    address public pendingOwner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function changeOwner(address _owner) onlyOwner public {
        require(_owner != address(0));
        pendingOwner = _owner;
    }
    
    function confirmOwner() public {
        require(pendingOwner == msg.sender);
        owner = pendingOwner;
        delete pendingOwner;
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
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    
    function balanceOf(address who) public constant returns (uint) {
        return balanceOf[who];
    }
    
    function approve(address _spender, uint _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract A_TAXPHONE is OWN, ERC20 {
    using SafeMath for uint256;
    
    struct ContractData {
        address parttwo;
        address partone;
        address ethdriver;
        uint256 maxInvestment;
        uint256 minInvestment;
        uint256 price;
        uint256 bank;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        address pendingOwner;
        address owner;
    }
    
    ContractData public data;
    
    constructor() public {
        data.parttwo = 0xbfd0Aea4b32030c985b467CF5bcc075364BD83e7;
        data.partone = 0xC92Af66B0d64B2E63796Fd325f2c7ff5c70aB8B7;
        data.ethdriver = 0x0311dEdC05cfb1870f25de4CD80dCF9e6bF4F2e8;
        data.maxInvestment = 10000000000000000000;
        data.minInvestment = 10000000000000000;
        data.price = 800000000;
        data.bank = 0;
        data.totalSupply = 0;
        data.decimals = 6;
        data.symbol = "TAXPHONE";
        data.name = "TAXPHONE";
        data.pendingOwner = address(0);
        data.owner = address(0);
    }
    
    function() payable public {
        require(msg.value > 0);
        require(msg.value >= data.minInvestment);
        require(msg.value <= data.maxInvestment);
        mintTokens(msg.sender, msg.value);
    }
    
    function mintTokens(address _who, uint256 _value) internal {
        uint256 tokens = _value / (data.price.mul(100).div(80));
        require(tokens > 0);
        require(balanceOf[_who] + tokens > balanceOf[_who]);
        
        data.totalSupply = data.totalSupply.add(tokens);
        balanceOf[_who] = balanceOf[_who].add(tokens);
        
        uint256 perc = _value.div(100);
        data.bank = data.bank.add(perc.mul(85));
        data.price = data.bank.div(data.totalSupply);
        
        uint256 minus = _value % (data.price.mul(100).div(80));
        
        emit Transfer(this, _who, tokens);
        
        owner.transfer(perc.mul(5));
        data.ethdriver.transfer(perc.mul(3));
        data.partone.transfer(perc.mul(2));
        data.parttwo.transfer(perc.mul(1));
        
        if(minus > 0) {
            _who.transfer(minus);
        }
    }
    
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        if(_to != address(this)) {
            require(balanceOf[_to] + _value >= balanceOf[_to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            uint256 change = _value.mul(data.price);
            require(address(this).balance >= change);
            
            if(data.totalSupply > _value) {
                uint256 plus = (address(this).balance.sub(data.bank)).div(data.totalSupply);
                data.bank = data.bank.sub(change);
                data.totalSupply = data.totalSupply.sub(_value);
                data.bank = data.bank.add(plus.mul(_value));
                data.price = data.bank.div(data.totalSupply);
                emit Transfer(msg.sender, _to, _value);
            }
            
            if(data.totalSupply == _value) {
                data.price = address(this).balance.div(data.totalSupply);
                data.price = data.price.mul(101).div(100);
                data.totalSupply = 0;
                data.bank = 0;
                emit Transfer(msg.sender, _to, _value);
                owner.transfer(address(this).balance.sub(change));
            }
            
            msg.sender.transfer(change);
        }
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        
        if(_to != address(this)) {
            require(balanceOf[_to] + _value >= balanceOf[_to]);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        } else {
            balanceOf[_from] = balanceOf[_from].sub(_value);
            uint256 change = _value.mul(data.price);
            require(address(this).balance >= change);
            
            if(data.totalSupply > _value) {
                uint256 plus = (address(this).balance.sub(data.bank)).div(data.totalSupply);
                data.bank = data.bank.sub(change);
                data.totalSupply = data.totalSupply.sub(_value);
                data.bank = data.bank.add(plus.mul(_value));
                data.price = data.bank.div(data.totalSupply);
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            }
            
            if(data.totalSupply == _value) {
                data.price = address(this).balance.div(data.totalSupply);
                data.price = data.price.mul(101).div(100);
                data.totalSupply = 0;
                data.bank = 0;
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
                owner.transfer(address(this).balance.sub(change));
            }
            
            _from.transfer(change);
        }
        return true;
    }
}