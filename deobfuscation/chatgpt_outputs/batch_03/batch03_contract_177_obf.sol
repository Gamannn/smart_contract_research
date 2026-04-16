pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ENToken is IERC20 {
    using SafeMath for uint256;

    address internal owner_;
    string public constant name = "ENTROPIUM";
    string public constant symbol = "ENT";
    uint8 public constant decimals = 18;
    uint256 internal totalSupply_ = 0;

    mapping(address => uint256) internal balances_;
    mapping(address => mapping(address => uint256)) internal allowed_;

    constructor() public payable {
        owner_ = msg.sender;
    }

    function owner() public view returns (address) {
        return owner_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances_[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed_[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances_[msg.sender]);
        require(to != address(0));

        balances_[msg.sender] = balances_[msg.sender].sub(value);
        balances_[to] = balances_[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances_[from]);
        require(value <= allowed_[from][msg.sender]);
        require(to != address(0));

        balances_[from] = balances_[from].sub(value);
        balances_[to] = balances_[to].add(value);
        allowed_[from][msg.sender] = allowed_[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address account, uint256 amount, uint8 percent) internal returns (bool) {
        require(account != address(0));
        require(amount > 0);

        totalSupply_ = totalSupply_.add(amount);
        balances_[account] = balances_[account].add(amount);

        if (percent < 100) {
            uint256 ownerAmount = amount.mul(percent).div(100 - percent);
            if (ownerAmount > 0) {
                totalSupply_ = totalSupply_.add(ownerAmount);
                balances_[owner_] = balances_[owner_].add(ownerAmount);
            }
        }

        emit Transfer(address(0), account, amount);
        return true;
    }

    function burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0));
        require(amount <= balances_[account]);

        totalSupply_ = totalSupply_.sub(amount);
        balances_[account] = balances_[account].sub(amount);
        emit Transfer(account, address(0), amount);
        return true;
    }
}

contract ENTROPIUM is ENToken {
    using SafeMath for uint256;

    uint256 private rate_ = 100;
    uint256 private start_ = now;
    uint256 private period_ = 90;
    uint256 private hardcap_ = 100000 ether;
    uint256 private softcap_ = 50000 ether;
    uint256 private ethtotal_ = 0;
    uint8 private percent_ = 10;

    mapping(address => uint256) private ethbalances_;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event RefundEvent(address indexed beneficiary, uint256 amount);
    event FinishEvent();

    constructor() public payable {}

    function () external payable {
        buyTokens(msg.sender);
    }

    function rate() public view returns (uint256) {
        return rate_;
    }

    function start() public view returns (uint256) {
        return start_;
    }

    function finished() public view returns (bool) {
        return (now > start_ + period_ * 1 days) || (ethtotal_ >= hardcap_);
    }

    function reachSoftcap() public view returns (bool) {
        return ethtotal_ >= softcap_;
    }

    function reachHardcap() public view returns (bool) {
        return ethtotal_ >= hardcap_;
    }

    function period() public view returns (uint256) {
        return period_;
    }

    function daysEnd() public view returns (uint256) {
        uint256 nowTime = now;
        uint256 endTime = start_ + period_ * 1 days;
        if (nowTime >= endTime) return 0;
        return (endTime - nowTime) / 1 days;
    }

    function hardcap() public view returns (uint256) {
        return hardcap_;
    }

    function setHardcap(uint256 hardcap) public {
        require(msg.sender == owner_);
        require(hardcap > softcap_);
        require(now >= start_);
        hardcap_ = hardcap;
    }

    function softcap() public view returns (uint256) {
        return softcap_;
    }

    function percent() public view returns (uint8) {
        return percent_;
    }

    function ethtotal() public view returns (uint256) {
        return ethtotal_;
    }

    function ethOf(address owner) public view returns (uint256) {
        return ethbalances_[owner];
    }

    function setOwner(address owner) public {
        require(msg.sender == owner_);
        require(owner != address(0) && owner != address(this));
        owner_ = owner;
    }

    function buyTokens(address beneficiary) internal {
        require(beneficiary != address(0));
        require(now >= start_ && now <= start_ + period_ * 1 days);
        require(ethtotal_ < hardcap_);

        uint256 weiAmount = msg.value;
        require(weiAmount != 0);

        uint256 tokenAmount = weiAmount.mul(rate_);
        mint(beneficiary, tokenAmount, percent_);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokenAmount);

        ethbalances_[beneficiary] = ethbalances_[beneficiary].add(weiAmount);
        ethtotal_ = ethtotal_.add(weiAmount);
    }

    function refund(uint256 amount) external returns (uint256) {
        require(now > start_ + period_ * 1 days && ethtotal_ < softcap_);

        uint256 tokenAmount = balances_[msg.sender];
        uint256 weiAmount = ethbalances_[msg.sender];

        require(amount > 0 && amount <= weiAmount && amount <= address(this).balance);

        if (tokenAmount > 0) {
            totalSupply_ = totalSupply_.sub(tokenAmount);
            balances_[msg.sender] = 0;
            emit Transfer(msg.sender, address(0), tokenAmount);
        }

        ethbalances_[msg.sender] = ethbalances_[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit RefundEvent(msg.sender);

        ethtotal_ = ethtotal_.sub(amount);
        return amount;
    }

    function finishICO(uint256 amount) external returns (uint256) {
        require(msg.sender == owner_);
        require(now >= start_ && ethtotal_ >= softcap_);
        require(amount <= address(this).balance);

        emit FinishEvent();
        msg.sender.transfer(amount);
        return amount;
    }

    function abalance(address owner) public view returns (uint256) {
        return owner.balance;
    }
}