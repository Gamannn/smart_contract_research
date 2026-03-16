```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Pausable is Ownable {
    bool public paused = false;
    
    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

interface IMonethaVoucher {
    function totalInSharedPool() external view returns (uint256);
    function toWei(uint256 value) external view returns (uint256);
    function fromWei(uint256 value) external view returns (uint256);
    function applyDiscount(address forAddress, uint256 vouchers) external returns (uint256 amountVouchers, uint256 amountWei);
    function applyPayback(address forAddress, uint256 amountWei) external returns (uint256 amountVouchers);
    function buyVouchers(uint256 vouchers) external payable;
    function sellVouchers(uint256 vouchers) external returns(uint256 weis);
    function releasePurchasedTo(address to, uint256 value) external returns (bool);
    function purchasedBy(address owner) external view returns (uint256);
}

contract Restricted is Ownable {
    mapping (address => bool) public isMonethaAddress;
    
    event MonethaAddressSet(address indexed address_, bool isMonethaAddress);

    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

    function setMonethaAddress(address _address, bool _isMonethaAddress) public onlyOwner {
        isMonethaAddress[_address] = _isMonethaAddress;
        emit MonethaAddressSet(_address, _isMonethaAddress);
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

contract CanReclaimEther is Ownable {
    event ReclaimEther(address indexed to, uint256 amount);

    function reclaimEther() external onlyOwner {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit ReclaimEther(owner, balance);
    }

    function reclaimEtherTo(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _to.transfer(_value);
        emit ReclaimEther(_to, _value);
    }
}

contract CanReclaimTokens is Ownable {
    using SafeERC20 for ERC20Basic;
    
    event ReclaimTokens(address indexed to, uint256 amount);

    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(owner, balance);
        emit ReclaimTokens(owner, balance);
    }

    function reclaimTokenTo(ERC20Basic token, address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        token.safeTransfer(_to, _value);
        emit ReclaimTokens(_to, _value);
    }
}

contract MonethaVoucher is IMonethaVoucher, Restricted, Pausable, IERC20, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event DiscountApplied(address indexed user, uint256 releasedVouchers, uint256 amountWeiTransferred);
    event PaybackApplied(address indexed user, uint256 addedVouchers, uint256 amountWeiEquivalent);
    event VouchersBought(address indexed user, uint256 vouchersBought);
    event VouchersSold(address indexed user, uint256 vouchersSold, uint256 amountWeiTransferred);
    event VoucherMthRateUpdated(uint256 oldVoucherMthRate, uint256 newVoucherMthRate);
    event MthEthRateUpdated(uint256 oldMthEthRate, uint256 newMthEthRate);
    event VouchersAdded(address indexed user, uint256 vouchersAdded);
    event VoucherReleased(address indexed user, uint256 releasedVoucher);
    event PurchasedVouchersReleased(address indexed from, address indexed to, uint256 vouchers);

    ERC20Basic public mthToken;
    
    mapping(address => uint256) public purchased;
    mapping(uint16 => uint256) public totalDistributedIn;
    mapping(uint16 => mapping(address => uint256)) public distributed;
    
    uint256 public voucherMthRate;
    uint256 public mthEthRate;
    uint256 public voucherMthEthRate;
    uint256 public totalPurchased;
    
    uint256 private constant DAY_IN_SECONDS = 86400;
    uint256 private constant YEAR_IN_SECONDS = 365 * DAY_IN_SECONDS;
    uint256 private constant LEAP_YEAR_IN_SECONDS = 366 * DAY_IN_SECONDS;
    uint256 private constant YEAR_IN_SECONDS_AVG = (YEAR_IN_SECONDS * 3 + LEAP_YEAR_IN_SECONDS) / 4;
    uint256 private constant HALF_YEAR_IN_SECONDS_AVG = YEAR_IN_SECONDS_AVG / 2;
    uint256 private constant RATE_COEFFICIENT = 10**18;
    uint256 private constant RATE_COEFFICIENT2 = RATE_COEFFICIENT * RATE_COEFFICIENT;

    constructor(uint256 _voucherMthRate, uint256 _mthEthRate, ERC20Basic _mthToken) public {
        require(_voucherMthRate > 0, "voucherMthRate should be greater than 0");
        require(_mthEthRate > 0, "mthEthRate should be greater than 0");
        require(_mthToken != address(0), "must be valid contract");
        
        voucherMthRate = _voucherMthRate;
        mthEthRate = _mthEthRate;
        mthToken = _mthToken;
        
        _updateVoucherMthEthRate();
    }

    function totalSupply() external view returns (uint256) {
        return _totalVouchersSupply();
    }

    function totalInSharedPool() external view returns (uint256) {
        return _vouchersInSharedPool(_currentHalfYear());
    }

    function totalDistributed() external view returns (uint256) {
        return _vouchersDistributed(_currentHalfYear());
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _distributedTo(owner, _currentHalfYear()).add(purchased[owner]);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        owner;
        spender;
        return 0;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        to;
        value;
        revert();
    }

    function approve(address spender, uint256 value) external returns (bool) {
        spender;
        value;
        revert();
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        from;
        to;
        value;
        revert();
    }

    function () external onlyMonetha payable {
    }

    function toWei(uint256 value) external view returns (uint256) {
        return _vouchersToWei(value);
    }

    function fromWei(uint256 value) external view returns (uint256) {
        return _weiToVouchers(value);
    }

    function applyDiscount(address forAddress, uint256 vouchers) external onlyMonetha returns (uint256 amountVouchers, uint256 amountWei) {
        require(forAddress != address(0), "zero address is not allowed");
        
        uint256 releasedVouchers = _releaseVouchers(forAddress, vouchers);
        if (releasedVouchers == 0) {
            return (0, 0);
        }
        
        uint256 amountToTransfer = _vouchersToWei(releasedVouchers);
        require(address(this).balance >= amountToTransfer, "insufficient funds");
        
        forAddress.transfer(amountToTransfer);
        emit DiscountApplied(forAddress, releasedVouchers, amountToTransfer);
        
        return (releasedVouchers, amountToTransfer);
    }

    function applyPayback(address forAddress, uint256 amountWei) external onlyMonetha returns (uint256 amountVouchers) {
        amountVouchers = _weiToVouchers(amountWei);
        require(_addVouchers(forAddress, amountVouchers), "vouchers must be added");
        emit PaybackApplied(forAddress, amountVouchers, amountWei);
    }

    function buyVouchers(uint256 vouchers) external onlyMonetha payable {
        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= vouchers, "insufficient vouchers present");
        require(msg.value == _vouchersToWei(vouchers), "insufficient funds");
        
        _addPurchasedTo(msg.sender, vouchers);
        emit VouchersBought(msg.sender, vouchers);
    }

    function sellVouchers(uint256 vouchers) external onlyMonetha returns(uint256 weis) {
        require(vouchers <= purchased[msg.sender], "Insufficient vouchers");
        
        _subPurchasedFrom(msg.sender, vouchers);
        weis = _vouchersToWei(vouchers);
        msg.sender.transfer(weis);
        
        emit VouchersSold(msg.sender, vouchers, weis);
    }

    function releasePurchasedTo(address to, uint256 value) external onlyMonetha returns (bool) {
        require(value <= purchased[msg.sender], "Insufficient Vouchers");
        require(to != address(0), "address should be valid");
        
        _subPurchasedFrom(msg.sender, value);
        _addVouchers(to, value);
        
        emit PurchasedVouchersReleased(msg.sender, to, value);
        return true;
    }

    function purchasedBy(address owner) external view returns (uint256) {
        return purchased[owner];
    }

    function updateVoucherMthRate(uint256 _voucherMthRate) external onlyMonetha {
        require(_voucherMthRate > 0, "should be greater than 0");
        require(voucherMthRate != _voucherMthRate, "same as previous value");
        
        emit VoucherMthRateUpdated(voucherMthRate, _voucherMthRate);
        voucherMthRate = _voucherMthRate;
        _updateVoucherMthEthRate();
    }

    function updateMthEthRate(uint256 _mthEthRate) external onlyMonetha {
        require(_mthEthRate > 0, "should be greater than 0");
        require(mthEthRate != _mthEthRate, "same as previous value");
        
        emit MthEthRateUpdated(mthEthRate, _mthEthRate);
        mthEthRate = _mthEthRate;
        _updateVoucherMthEthRate();
    }

    function _addPurchasedTo(address to, uint256 value) internal {
        purchased[to] = purchased[to].add(value);
        totalPurchased = totalPurchased.add(value);
    }

    function _subPurchasedFrom(address from, uint256 value) internal {
        purchased[from] = purchased[from].sub(value);
        totalPurchased = totalPurchased.sub(value);
    }

    function _updateVoucherMthEthRate() internal {
        voucherMthEthRate = voucherMthRate.mul(mthEthRate);
    }

    function _addVouchers(address to, uint256 value) internal returns (bool) {
        require(to != address(0), "zero address is not allowed");
        
        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= value, "must be less or equal than vouchers present in shared pool");
        
        uint256 oldDist = totalDistributedIn[currentHalfYear];
        totalDistributedIn[currentHalfYear] = oldDist.add(value);
        
        uint256 oldBalance = distributed[currentHalfYear][to];
        distributed[currentHalfYear][to] = oldBalance.add(value);
        
        emit VouchersAdded(to, value);
        return true;
    }

    function _releaseVouchers(address from, uint256 value) internal returns (uint256) {
        require(from != address(0), "must be valid address");
        
        uint16 currentHalfYear = _currentHalfYear();
        uint256 released = 0;
        
        if (currentHalfYear > 0) {
            released = released.add(_releaseVouchers(from, value, currentHalfYear - 1));
            value = value.sub(released);
        }
        
        released = released.add(_releaseVouchers(from, value, currentHalfYear));
        emit VoucherReleased(from, released);
        
        return released;
    }

    function _releaseVouchers(address from, uint256 value, uint16 currentHalfYear) internal returns (uint256) {
        if (value == 0) {
            return 0;
        }
        
        uint256 oldBalance = distributed[currentHalfYear][from];
        uint256 subtracted = value;
        
        if (oldBalance <= value) {
            delete distributed[currentHalfYear][from];
            subtracted = oldBalance;
        } else {
            distributed[currentHalfYear][from] = oldBalance.sub(value);
        }
        
        uint256 oldDist = totalDistributedIn[currentHalfYear];
        if (oldDist == subtracted) {
            delete totalDistributedIn[currentHalfYear];
        } else {
            totalDistributedIn[currentHalfYear] = oldDist.sub(subtracted);
        }
        
        return subtracted;
    }

    function _vouchersToWei(uint256 value) internal view returns (uint256) {
        return value.mul(RATE_COEFFICIENT2).div(voucherMthEthRate);
    }

    function _weiToVouchers(uint256 value) internal view returns (uint256) {
        return value.mul(voucherMthEthRate).div(RATE_COEFFICIENT2);
    }

    function _mthToVouchers(uint256 value) internal view returns (uint256) {
        return value.mul(voucherMthRate).div(RATE_COEFFICIENT);
    }

    function _weiToMth(uint256 value) internal view returns (uint256) {
        return value.mul(mthEthRate).div(RATE_COEFFICIENT);
    }

    function _totalVouchersSupply() internal view returns (uint256) {
        return _mthToVouchers(mthToken.balanceOf(address(this)));
    }

    function _vouchersInSharedPool(uint16 currentHalfYear) internal view returns (uint256) {
        return _totalVouchersSupply().sub(_vouchersDistributed(currentHalfYear)).sub(totalPurchased);
    }

    function _vouchersDistributed(uint16 currentHalfYear) internal view returns (uint256) {
        uint256 dist = totalDistributedIn[currentHalfYear];
        if (currentHalfYear > 0) {
            dist = dist.add(totalDistributedIn[currentHalfYear - 1]);
        }
        return dist;
    }

    function _distributedTo(address owner, uint16 currentHalfYear) internal view returns (uint256) {
        uint256 balance = distributed[currentHalfYear][owner];
        if (currentHalfYear >