```solidity
pragma solidity ^0.5.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Token is Ownable, ERC20Interface, Pausable {
    using SafeMath for uint256;

    string private name = "Token V1.1";
    string private symbol = "COM";
    uint8 private decimals = 6;
    uint256 private totalSupply_;
    mapping(address => uint256) internal balances;
    uint8[10] private rewardLevels = [5, 4, 3, 2, 1];
    uint256 private constantFactor = 9765625;

    event Donate(address indexed donor, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event JoinWhiteList(address indexed referrer, address indexed referee);

    constructor() public {
        _addToWhitelist(address(this), msg.sender);
    }

    function() external payable whenNotPaused {
        require(msg.value >= 1 ether, "Token: must send at least 1 ether");
        require(balanceOf(msg.sender) == 0, "Token: balance is greater than zero");
        require(!isWhitelisted(msg.sender), "Token: already whitelisted");
        require(!registered[msg.sender], "Token: already registered");

        uint256 tokens = 1024000000;
        uint256 rate = tokens.mul(constantFactor).div(100);
        uint256 amount = msg.value.sub(rate);

        registered[msg.sender] = true;
        msg.sender.transfer(amount);
        _mint(msg.sender, tokens);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (value == 0 && isWhitelisted(to) && !isWhitelisted(msg.sender)) {
            _addToWhitelist(to, msg.sender);
            return _transfer(to, value);
        } else {
            return _transfer(to, value);
        }
    }

    function isWhitelisted(address account) private view returns (bool) {
        return whitelist[account] != address(0);
    }

    function _addToWhitelist(address referrer, address referee) private returns (bool) {
        whitelist[referee] = referrer;
        referrals[referrer].push(referee);
        whitelistCounter = whitelistCounter.add(1);
        emit JoinWhiteList(referrer, referee);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        require(value <= balances[from], "Token: insufficient balance");
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) private {
        totalSupply_ = totalSupply_.add(value);
        balances[account] = balances[account].add(value);
        emit Mint(account, value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) private {
        require(value <= balances[account], "Token: burn amount exceeds balance");
        balances[account] = balances[account].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(account, value);
        emit Transfer(account, address(0), value);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function getReferrals(address account) public view returns (address[] memory) {
        return referrals[account];
    }

    function getReferrer(address account) public view returns (address) {
        return whitelist[account];
    }

    function getRewardLevels() public view returns (uint8[10] memory) {
        return rewardLevels;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    function getDecimals() public view returns (uint8) {
        return decimals;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Token: withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Token: insufficient balance");
        to.transfer(amount);
    }

    function mint(address to, uint256 value) external onlyOwner {
        _mint(to, value);
    }

    function burnFrom(address from, uint256 value) external onlyOwner {
        _burn(from, value);
    }

    function setRate(uint256 newRate, uint256 newFactor) external onlyOwner {
        rate = newRate;
        constantFactor = newFactor;
    }
}

contract MinerContract is Ownable {
    using SafeMath for uint256;

    string private name = "MinerContract V1.1";

    struct Miner {
        uint256 startTime;
        uint256 amount;
        bool active;
    }

    Token private token;
    mapping(address => Miner) private miners;
    uint256 private rewardFactor = 10;

    constructor(Token _token) public {
        token = _token;
    }

    function() external payable {
        if (msg.value == 0) {
            _getReward(msg.sender);
        } else {
            _deposit(msg.sender, msg.value);
            _distributeRewards(msg.sender, msg.value);
        }
    }

    function _deposit(address account, uint256 amount) private {
        require(!miners[account].active, "MinerContract: already a miner");
        uint256 reward = _calculateReward(amount);
        uint256 tokens = reward.mul(rewardFactor).div(100);
        token.transfer(account, tokens);
        miners[account] = Miner(now, amount, true);
    }

    function _distributeRewards(address account, uint256 amount) private {
        uint8[10] memory levels = token.getRewardLevels();
        address current = account;
        for (uint8 i = 0; i < levels.length; i++) {
            current = token.getReferrer(current);
            if (current == address(0)) {
                break;
            }
            uint256 referralsCount = token.getReferrals(current).length;
            if (referralsCount < i + 1) {
                continue;
            }
            uint256 reward = amount.mul(levels[i]).div(100);
            require(address(this).balance >= reward, "MinerContract: insufficient balance");
            address payable recipient = address(uint160(current));
            recipient.transfer(reward);
        }
    }

    function _getReward(address account) private {
        require(miners[account].active, "MinerContract: not a miner");
        Miner storage miner = miners[account];
        require(now > miner.startTime, "MinerContract: reward not available yet");
        uint256 elapsedTime = now.sub(miner.startTime);
        uint256 reward = 0;
        uint256 tokenReward = 0;
        if (elapsedTime > 12 * 30 days) {
            reward = miner.amount.mul(2);
            tokenReward = _calculateTokenReward(miner.amount).mul(11).div(5);
        } else if (elapsedTime > 6 * 30 days) {
            reward = miner.amount.mul(3).div(2);
            tokenReward = _calculateTokenReward(miner.amount).mul(3).div(2);
        } else if (elapsedTime > 3 * 30 days) {
            reward = miner.amount;
            tokenReward = _calculateTokenReward(miner.amount);
        } else if (elapsedTime > 1 * 30 days) {
            reward = miner.amount.mul(3).div(5);
            tokenReward = _calculateTokenReward(miner.amount).mul(3).div(5);
        } else {
            reward = miner.amount.mul(1).div(2);
            tokenReward = _calculateTokenReward(miner.amount).mul(2).div(5);
        }
        require(address(this).balance >= reward, "MinerContract: insufficient balance");
        require(token.balanceOf(address(this)) >= tokenReward, "MinerContract: insufficient token balance");
        miner.active = false;
        address payable recipient = address(uint160(account));
        recipient.transfer(reward);
        token.transfer(account, tokenReward);
    }

    function _calculateReward(uint256 amount) private view returns (uint256) {
        (uint256 rate, uint256 factor) = token.getRate();
        return amount.mul(rate).div(factor);
    }

    function _calculateTokenReward(uint256 amount) private view returns (uint256) {
        (uint256 rate, uint256 factor) = token.getRate();
        return amount.mul(factor).div(rate);
    }

    function calculateReward(uint256 amount) public view returns (uint256) {
        return _calculateReward(amount);
    }

    function calculateTokenReward(uint256 amount) public view returns (uint256) {
        return _calculateTokenReward(amount);
    }

    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "MinerContract: withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "MinerContract: insufficient balance");
        to.transfer(amount);
    }

    function withdrawTokens(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "MinerContract: withdraw to the zero address");
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "MinerContract: insufficient token balance");
        token.transfer(to, amount);
    }
}
```