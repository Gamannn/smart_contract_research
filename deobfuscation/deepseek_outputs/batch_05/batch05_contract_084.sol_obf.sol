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
        return a / b;
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
    event Pause();
    event Unpause();

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
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract COM is Ownable, ERC20Basic, Pausable {
    using SafeMath for uint256;

    string private _name = "COM V1.1";
    string private _symbol = "COM";
    uint8 private _decimals = 6;
    uint256 private _totalSupply;
    
    mapping(address => uint256) internal _balances;
    
    uint8[10] private _referralRates = [5, 4, 3, 2, 1];
    
    uint256 private _k2 = 9765625;
    
    event Donate(address indexed donor, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event JoinWhiteList(address indexed referrer, address indexed referee);

    mapping(address => address) private _referrers;
    mapping(address => address[]) private _referees;
    mapping(address => bool) private _registered;
    uint256 private _whitelistCount = 0;
    
    uint256 private _k1 = 1024000000;
    
    constructor() public {
        _addToWhitelist(address(this), msg.sender);
    }

    function() external payable whenNotPaused {
        require(msg.value >= 1 ether, "COM: must greater 1 ether");
        require(!(balanceOf(msg.sender) > 0), "COM: balance is greater than zero");
        require(!_isWhitelisted(msg.sender), "COM: already whitelisted");
        require(!_registered[msg.sender], "COM: already register");
        
        uint256 tokens = 1024000000;
        uint256 etherCost = tokens.mul(_k2).div(_k1);
        uint256 refund = msg.value.sub(etherCost);
        
        _registered[msg.sender] = true;
        msg.sender.transfer(refund);
        _mint(msg.sender, tokens);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (value == 0 && _isWhitelisted(to) && !_isWhitelisted(msg.sender)) {
            _addToWhitelist(to, msg.sender);
            return _transfer(msg.sender, to, value);
        } else {
            return _transfer(msg.sender, to, value);
        }
    }

    function _isWhitelisted(address account) private view returns(bool) {
        return _referrers[account] != address(0);
    }

    function _addToWhitelist(address referrer, address referee) private returns (bool) {
        _referrers[referee] = referrer;
        _referees[referrer].push(referee);
        _whitelistCount = _whitelistCount.add(1);
        emit JoinWhiteList(referrer, referee);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        require(value <= _balances[from], "COM: insufficient balance");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 amount) private {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(amount <= _balances[account], "COM: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function getReferees(address account) public view returns (address[] memory) {
        return _referees[account];
    }

    function getReferrer(address account) public view returns(address) {
        return _referrers[account];
    }

    function getReferralRates() public view returns(uint8[10] memory) {
        return _referralRates;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function whitelistCount() public view returns (uint256) {
        return _whitelistCount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getExchangeRate() public view returns (uint256, uint256) {
        return (_k1, _k2);
    }

    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "COM: recipient is the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "COM: amount exceeds balance");
        recipient.transfer(amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function setExchangeRate(uint256 k1, uint256 k2) external onlyOwner {
        _k1 = k1;
        _k2 = k2;
    }
}

contract Miner is Ownable {
    using SafeMath for uint256;

    string private _name = "Miner V1.1";
    
    struct MinerInfo {
        uint256 startTime;
        uint256 deposit;
        bool isActive;
    }
    
    COM private _token;
    
    mapping(address => MinerInfo) private _miners;
    uint256 _feeRate = 10;
    
    constructor(COM token) public {
        _token = token;
    }

    function() external payable {
        if (msg.value == 0) {
            _getAward(msg.sender);
        } else {
            _deposit(msg.sender, msg.value);
            _distributeReferralRewards(msg.sender, msg.value);
        }
    }

    function _deposit(address account, uint256 amount) private {
        require(!_miners[account].isActive, "COM: you are already mining");
        uint256 tokens = _etherToToken(amount);
        uint256 fee = tokens.mul(_feeRate).div(100);
        _token.transfer(account, fee);
        
        MinerInfo memory miner = MinerInfo(now, amount, true);
        _miners[msg.sender] = miner;
    }

    function _distributeReferralRewards(address referrer, uint256 amount) private {
        uint8[10] memory rates = _token.getReferralRates();
        address current = referrer;
        
        for (uint8 i = 0; i < rates.length; i++) {
            current = _token.getReferrer(current);
            if (current == address(0)) {
                break;
            }
            
            uint256 refereeCount = _token.getReferees(current).length;
            if (refereeCount < i + 1) {
                continue;
            }
            
            uint256 reward = amount.mul(rates[i]).div(100);
            require(address(this).balance >= reward, "balance not enough");
            address payable recipient = address(uint160(current));
            recipient.transfer(reward);
        }
    }

    function _getAward(address account) private {
        require(_miners[account].isActive, "COM: you are not a miner");
        MinerInfo storage miner = _miners[msg.sender];
        require(now > miner.startTime, "COM: startTime is illegal");
        
        uint256 timePassed = now.sub(miner.startTime);
        uint256 etherReward = 0;
        uint256 tokenReward = 0;
        
        if (timePassed > 12 * 30 days) {
            etherReward = miner.deposit.mul(2);
            tokenReward = _etherToToken(miner.deposit).mul(11).div(5);
        } else if(timePassed > 6 * 30 days) {
            etherReward = miner.deposit.mul(3).div(2);
            tokenReward = _etherToToken(miner.deposit).mul(3).div(2);
        } else if (timePassed > 3 * 30 days) {
            etherReward = miner.deposit;
            tokenReward = _etherToToken(miner.deposit);
        } else if (timePassed > 1 * 30 days) {
            etherReward = miner.deposit.mul(3).div(5);
            tokenReward = _etherToToken(miner.deposit).mul(3).div(5);
        } else {
            etherReward = miner.deposit.mul(1).div(2);
            tokenReward = _etherToToken(miner.deposit).mul(2).div(5);
        }
        
        require(address(this).balance >= etherReward, "COM: ether balance is not enough");
        require(_token.balanceOf(address(this)) >= tokenReward, "COM: token balance is not enough");
        
        miner.isActive = false;
        address payable recipient = address(uint160(account));
        recipient.transfer(etherReward);
        _token.transfer(account, tokenReward);
    }

    function _etherToToken(uint256 amount) private view returns (uint256) {
        (uint256 k1, uint256 k2) = _token.getExchangeRate();
        return amount.mul(k1).div(k2);
    }

    function _tokenToEther(uint256 amount) private view returns (uint256) {
        (uint256 k1, uint256 k2) = _token.getExchangeRate();
        return amount.mul(k2).div(k1);
    }

    function etherToToken(uint256 amount) public view returns (uint256) {
        return _etherToToken(amount);
    }

    function tokenToEther(uint256 amount) public view returns (uint256) {
        return _tokenToEther(amount);
    }

    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "COM: recipient is the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "COM: amount exceeds balance");
        recipient.transfer(amount);
    }

    function withdrawTokens(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "COM: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount, "COM: amount exceeds balance");
        _token.transfer(recipient, amount);
    }
}
```