pragma solidity ^0.4.24;

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

contract DigitalHumanityToken {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) public soldAmountUSD;
    uint256 public totalSupply;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    string public constant name = "Digital Humanity Token";
    string public constant symbol = "DHT";
    uint8 public constant decimals = 18;

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function burn(uint256 value) public {
        require(value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Burn(burner, value);
    }

    function purchase(address buyer) public payable returns (bool) {
        require(address(this).balance > 0);

        uint256 tokenAmount = balances[buyer];
        uint256 usdAmount = soldAmountUSD[buyer];

        require(tokenAmount > 0);
        require(usdAmount > 0);

        balances[buyer] = 0;
        balances[address(this)] = balances[address(this)].add(tokenAmount);

        approve(buyer, usdAmount);
        buyer.transfer(usdAmount);

        return true;
    }

    function calculateTokenAmount(uint256 ethAmount, uint256 rate) internal pure returns (uint256) {
        return ethAmount.mul(rate).div(100);
    }
}