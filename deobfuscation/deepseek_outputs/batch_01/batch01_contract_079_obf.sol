pragma solidity ^0.4.25;

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

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
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

contract ERC20Interface {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    function balanceOf(address who) public constant returns (uint) {
        return balanceOf[who];
    }

    function approve(address spender, uint value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function allowance(address owner, address spender) public constant returns (uint remaining) {
        return allowance[owner][spender];
    }

    modifier validPayload(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract A_NEXT_LEVEL is Ownable, ERC20Interface {
    using SafeMath for uint256;

    struct ContractData {
        address ethdriver;
        uint256 maxInvestment;
        uint256 minInvestment;
        uint256 price;
        uint256 totalFunds;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        address newOwner;
        address owner;
    }

    ContractData public data = ContractData(
        0xB453AA2Cdc2F9241d2c451053DA8268B34b4227f,
        10000000000000000000,
        10000000000000000,
        800000000,
        0,
        0,
        6,
        "NLCLUB",
        "NEXT LEVEL CLUB",
        address(0),
        address(0)
    );

    function() public payable {
        require(msg.value > 0);
        require(msg.value >= data.minInvestment);
        require(msg.value <= data.maxInvestment);
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address buyer, uint256 amount) internal {
        uint256 tokens = amount / (data.price * 10 / 8);
        require(tokens > 0);
        require(balanceOf[buyer] + tokens > balanceOf[buyer]);

        data.totalSupply = data.totalSupply.add(tokens);
        balanceOf[buyer] = balanceOf[buyer].add(tokens);

        uint256 fee = amount.div(100);
        data.totalFunds = data.totalFunds.add(fee.mul(85));
        data.price = data.totalFunds.div(data.totalSupply);

        uint256 change = amount % (data.price * 10 / 8);
        require(change > 0);

        emit Transfer(this, buyer, tokens);

        amount = 0;
        tokens = 0;

        data.owner.transfer(fee.mul(5));
        data.ethdriver.transfer(fee.mul(5));
        buyer.transfer(change);

        change = 0;
    }

    function transfer(address to, uint value) public validPayload(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        if (to != address(this)) {
            require(balanceOf[to] + value >= balanceOf[to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            emit Transfer(msg.sender, to, value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            uint256 etherAmount = value.mul(data.price);
            require(address(this).balance >= etherAmount);

            if (data.totalSupply > value) {
                uint256 pricePerToken = (address(this).balance - data.totalFunds).div(data.totalSupply);
                data.totalFunds = data.totalFunds.sub(etherAmount);
                data.totalSupply = data.totalSupply.sub(value);
                data.totalFunds = data.totalFunds.add(pricePerToken.mul(value));
                data.price = data.totalFunds.div(data.totalSupply);
                emit Transfer(msg.sender, to, value);
            }

            if (data.totalSupply == value) {
                data.price = address(this).balance / data.totalSupply;
                data.price = (data.price.mul(101)).div(100);
                data.totalSupply = 0;
                data.totalFunds = 0;
                emit Transfer(msg.sender, to, value);
                data.owner.transfer(address(this).balance - etherAmount);
            }

            msg.sender.transfer(etherAmount);
        }
        return true;
    }

    function transferFrom(address from, address to, uint value) public validPayload(3 * 32) returns (bool success) {
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);

        if (to != address(this)) {
            require(balanceOf[to] + value >= balanceOf[to]);
            balanceOf[from] = balanceOf[from].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
        } else {
            balanceOf[from] = balanceOf[from].sub(value);
            uint256 etherAmount = value.mul(data.price);
            require(address(this).balance >= etherAmount);

            if (data.totalSupply > value) {
                uint256 pricePerToken = (address(this).balance - data.totalFunds).div(data.totalSupply);
                data.totalFunds = data.totalFunds.sub(etherAmount);
                data.totalSupply = data.totalSupply.sub(value);
                data.totalFunds = data.totalFunds.add(pricePerToken.mul(value));
                data.price = data.totalFunds.div(data.totalSupply);
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            }

            if (data.totalSupply == value) {
                data.price = address(this).balance / data.totalSupply;
                data.price = (data.price.mul(101)).div(100);
                data.totalSupply = 0;
                data.totalFunds = 0;
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
                data.owner.transfer(address(this).balance - etherAmount);
            }

            from.transfer(etherAmount);
        }
        return true;
    }
}