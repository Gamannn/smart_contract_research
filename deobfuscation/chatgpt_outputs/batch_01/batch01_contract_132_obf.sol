```solidity
pragma solidity ^0.4.25;

contract Ownable {
    address public owner;
    address public pendingOwner;

    constructor() public payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        pendingOwner = _newOwner;
    }

    function confirmOwner() public {
        require(pendingOwner == msg.sender);
        owner = pendingOwner;
        pendingOwner = address(0);
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

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    function balanceOf(address who) public view returns (uint256) {
        return balanceOf[who];
    }

    function approve(address _spender, uint256 _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract TaxPhoneToken is Ownable, ERC20 {
    using SafeMath for uint256;

    struct TokenData {
        address partTwo;
        address partOne;
        address ethDriver;
        uint256 maxContribution;
        uint256 minContribution;
        uint256 price;
        uint256 bank;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
    }

    TokenData public tokenData = TokenData(
        0xbfd0Aea4b32030c985b467CF5bcc075364BD83e7,
        0xC92Af66B0d64B2E63796Fd325f2c7ff5c70aB8B7,
        0x0311dEdC05cfb1870f25de4CD80dCF9e6bF4F2e8,
        10 ether,
        0.01 ether,
        800000000,
        0,
        0,
        6,
        "TAXPHONE",
        "TAXPHONE"
    );

    function() public payable {
        require(msg.value > 0);
        require(msg.value >= tokenData.minContribution);
        require(msg.value <= tokenData.maxContribution);
        mintTokens(msg.sender, msg.value);
    }

    function mintTokens(address _to, uint256 _value) internal {
        uint256 tokens = _value.div(tokenData.price.mul(100).div(80));
        require(tokens > 0);
        require(balanceOf[_to].add(tokens) > balanceOf[_to]);

        tokenData.totalSupply = tokenData.totalSupply.add(tokens);
        balanceOf[_to] = balanceOf[_to].add(tokens);

        uint256 perc = _value.div(100);
        tokenData.bank = tokenData.bank.add(perc.mul(85));
        tokenData.price = tokenData.bank.div(tokenData.totalSupply);

        uint256 remainder = _value.mod(tokenData.price.mul(100).div(80));
        emit Transfer(this, _to, tokens);

        owner.transfer(perc.mul(5));
        tokenData.ethDriver.transfer(perc.mul(3));
        tokenData.partOne.transfer(perc.mul(2));
        tokenData.partTwo.transfer(perc.mul(1));

        if (remainder > 0) {
            _to.transfer(remainder);
        }
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        if (_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            uint256 change = _value.mul(tokenData.price);
            require(address(this).balance >= change);

            if (tokenData.totalSupply > _value) {
                uint256 plus = (address(this).balance.sub(tokenData.bank)).div(tokenData.totalSupply);
                tokenData.bank = tokenData.bank.sub(change);
                tokenData.totalSupply = tokenData.totalSupply.sub(_value);
                tokenData.bank = tokenData.bank.add(plus.mul(_value));
                tokenData.price = tokenData.bank.div(tokenData.totalSupply);
                emit Transfer(msg.sender, _to, _value);
            }

            if (tokenData.totalSupply == _value) {
                tokenData.price = address(this).balance.div(tokenData.totalSupply);
                tokenData.price = tokenData.price.mul(101).div(100);
                tokenData.totalSupply = 0;
                tokenData.bank = 0;
                emit Transfer(msg.sender, _to, _value);
                owner.transfer(address(this).balance.sub(change));
            }

            msg.sender.transfer(change);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
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
            uint256 change = _value.mul(tokenData.price);
            require(address(this).balance >= change);

            if (tokenData.totalSupply > _value) {
                uint256 plus = (address(this).balance.sub(tokenData.bank)).div(tokenData.totalSupply);
                tokenData.bank = tokenData.bank.sub(change);
                tokenData.totalSupply = tokenData.totalSupply.sub(_value);
                tokenData.bank = tokenData.bank.add(plus.mul(_value));
                tokenData.price = tokenData.bank.div(tokenData.totalSupply);
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            }

            if (tokenData.totalSupply == _value) {
                tokenData.price = address(this).balance.div(tokenData.totalSupply);
                tokenData.price = tokenData.price.mul(101).div(100);
                tokenData.totalSupply = 0;
                tokenData.bank = 0;
                emit Transfer(_from, _to, _value);
                allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
                owner.transfer(address(this).balance.sub(change));
            }

            _from.transfer(change);
        }

        return true;
    }
}
```