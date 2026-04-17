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
        return a / b;
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
    mapping (address => mapping (address => uint256)) internal allowed;

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Token is StandardToken, Ownable {
    string public constant name = "4ArtCoin";
    string public constant symbol = "4Art";
    uint8 public constant decimals = 18;
    uint256 public buyPrice;
    uint256 public sellPrice;
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

    function Token() public {
        balances[msg.sender] = 4354000000e18;
        founderAddress1 = 0x6c7dd291a92b819f38b86f04681b7aa2b137ca2b;
        founderAddress2 = 0xd4b7828f404b5c3e5c0f9925611a415ba517de64;
        founderAddress3 = 0x4b5ab188b264a34076020db29ed22c461fe8aaf1;
        founderAddress4 = 0x022d7af8563d1ed17fda09eb4183250a2c410c76;
        founderAddress5 = 0x2d691f4648f75008090e93a22df695567ddd23ee;
        teamAddress = 0x14463985f44e1d5b52881b6cc8490b8a78cdbe4d;
        adviserAddress = 0xf6c4de26ab617178cfdd9de20a2044d69ff67d11;
        partnershipAddress = 0x0a8d4f50f1ab1e2bd47c1f4979ff3a1aa07ebc97;
        bountyAddress = 0xa27bc3b90b2051379036f2e83e7e2274d936b61a;
        affiliateAddress = 0xbe7194a70730eba492f5869d0810584beedae943;
        miscAddress = 0xc5ed5782374fa35f801bf8256a1824bcb408e7de;

        balances[founderAddress1] = 1390000000e18;
        balances[founderAddress2] = 27500000e18;
        balances[founderAddress3] = 27500000e18;
        balances[founderAddress4] = 3500000e18;
        balances[founderAddress5] = 400000e18;
        balances[teamAddress] = 39000000e18;
        balances[adviserAddress] = 39000000e18;
        balances[partnershipAddress] = 364000000e18;
        balances[bountyAddress] = 100000000e18;
        balances[affiliateAddress] = 100000000e18;
        balances[miscAddress] = 100000000e18;
    }

    function () public payable {}

    function setPrices(uint256 newBuyPrice, uint256 newSellPrice) public onlyOwner {
        buyPrice = newBuyPrice;
        sellPrice = newSellPrice;
    }

    function buy() payable public {
        require(now > 1543536000);
        uint amount = msg.value.div(buyPrice);
        _transfer(owner, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(now > 1543536000);
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        uint256 revenue = amount.mul(sellPrice);
        require(this.balance >= revenue);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[owner] = balances[owner].add(amount);
        emit Transfer(msg.sender, owner, amount);
        msg.sender.transfer(revenue);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balances[from] >= value);
        require(balances[to].add(value) > balances[to]);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
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

    modifier onlyAfter(uint256 time) {
        if(msg.sender != owner) {
            require(now > time);
        }
        _;
    }

    modifier onlyDuring(uint256 startTime, uint256 endTime) {
        if(now > startTime && now < endTime) {
            _;
        }
    }
}