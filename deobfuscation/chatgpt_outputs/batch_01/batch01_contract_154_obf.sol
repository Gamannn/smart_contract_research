pragma solidity ^0.4.19;

contract BaseToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
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
        require(now >= tokenDetails.icoBegintime && now <= tokenDetails.icoEndtime);

        uint256 tokenValue = (msg.value * tokenDetails.icoRatio * 10 ** uint256(tokenDetails.decimals)) / (1 ether / 1 wei);
        if (tokenValue == 0 || balanceOf[tokenDetails.icoSender] < tokenValue) {
            revert();
        }

        _transfer(tokenDetails.icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        tokenDetails.icoHolder.transfer(balance);
        Withdraw(msg.sender, tokenDetails.icoHolder, balance);
    }
}

contract CustomToken is BaseToken, ICOToken {
    struct TokenDetails {
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

    TokenDetails public tokenDetails;

    function CustomToken() public {
        tokenDetails.totalSupply = 81000000000000000000000000;
        tokenDetails.name = "PublicKey";
        tokenDetails.symbol = "PKC";
        tokenDetails.decimals = 18;
        balanceOf[0x58cbc34576efc4f2591fbc6258f89961e7e34d48] = tokenDetails.totalSupply;
        Transfer(address(0), 0x58cbc34576efc4f2591fbc6258f89961e7e34d48, tokenDetails.totalSupply);

        tokenDetails.icoRatio = 11000;
        tokenDetails.icoBegintime = 1527811200;
        tokenDetails.icoEndtime = 1622559600;
        tokenDetails.icoSender = 0x58cbc34576efc4f2591fbc6258f89961e7e34d48;
        tokenDetails.icoHolder = 0x58cbc34576efc4f2591fbc6258f89961e7e34d48;
    }

    function() public payable {
        ico();
    }
}