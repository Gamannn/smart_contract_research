pragma solidity ^0.4.19;

contract BaseToken {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ICOToken is BaseToken {
    event ICO(address indexed from, uint256 indexed value, uint256 tokenValue);
    event Withdraw(address indexed from, address indexed holder, uint256 value);
    
    function ico() public payable {
        require(now >= config.icoBegintime && now <= config.icoEndtime);
        
        uint256 tokenValue = (msg.value * config.icoRatio * 10 ** uint256(config.decimals)) / (1 ether);
        
        if (tokenValue == 0 || balanceOf[config.icoSender] < tokenValue) {
            revert();
        }
        
        _transfer(config.icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        config.icoHolder.transfer(balance);
        Withdraw(msg.sender, config.icoHolder, balance);
    }
}

contract CustomToken is BaseToken, ICOToken {
    struct TokenConfig {
        address icoHolder;
        address icoSender;
        uint256 icoEndtime;
        uint256 icoBegintime;
        uint256 icoRatio;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
    }
    
    TokenConfig public config;
    
    function CustomToken() public {
        config.totalSupply = 81000000000000000000000000;
        config.name = 'PublicKey';
        config.symbol = 'PKC';
        config.decimals = 18;
        
        address initialHolder = 0x58cbc34576efc4f2591fbc6258f89961e7e34d48;
        balanceOf[initialHolder] = config.totalSupply;
        Transfer(address(0), initialHolder, config.totalSupply);
        
        config.icoRatio = 11000;
        config.icoBegintime = 1527811200;
        config.icoEndtime = 1622559600;
        config.icoSender = initialHolder;
        config.icoHolder = initialHolder;
    }
    
    function() public payable {
        ico();
    }
}