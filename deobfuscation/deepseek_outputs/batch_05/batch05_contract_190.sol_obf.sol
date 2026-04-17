```solidity
pragma solidity ^0.4.18;

interface IWeightFormula {
    function calculatePurchaseReturn(
        uint256 totalSupply,
        uint256 reserveBalance,
        uint32 weight,
        uint256 depositAmount
    ) external view returns (uint256);
    
    function calculateSaleReturn(
        uint256 totalSupply,
        uint256 reserveBalance,
        uint32 weight,
        uint256 sellAmount
    ) external view returns (uint256);
}

interface IToken {
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint value) external returns (bool success);
    function transfer(address to, uint value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

interface ITokenReceiver {
    function tokenFallback(address from, uint256 value, address to, bytes data) external;
}

contract Ownable {
    address public owner;
    mapping (address => bool) public admins;
    
    constructor() public {
        owner = msg.sender;
        admins[owner] = true;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender);
        _;
    }
    
    function addAdmin(address newAdmin) onlyOwner public {
        grantAdminStatus(newAdmin);
    }
    
    function grantAdminStatus(address newAdmin) internal {
        admins[newAdmin] = true;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function revokeAdminStatus(address admin) onlyOwner public {
        admins[admin] = false;
    }
}

contract BondingCurve is Ownable, ITokenReceiver {
    bool public enabled = false;
    IWeightFormula public weightFormula;
    uint32 public weight;
    uint32 public fee = 5000;
    IToken public tokenContract;
    uint32 public issuedSupplyRatio;
    
    constructor(IToken _tokenContract, IWeightFormula _weightFormula, uint32 _weight) public {
        tokenContract = _tokenContract;
        weightFormula = _weightFormula;
        weight = _weight;
    }
    
    event Buy(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event Sell(address indexed seller, uint256 tokenAmount, uint256 etherAmount);
    
    function depositTokens(uint amount) onlyOwner public {
        tokenContract.transferFrom(msg.sender, this, amount);
    }
    
    function fund() onlyOwner public payable {
    }
    
    function withdrawTokens(uint amount) onlyOwner public {
        tokenContract.transfer(msg.sender, amount);
    }
    
    function withdrawEther(uint amount) onlyOwner public {
        msg.sender.transfer(amount);
    }
    
    function withdrawCollectedFees(uint amount) onlyAdmin public {
        require(amount <= collectedFees);
        msg.sender.transfer(amount);
    }
    
    function enable() onlyAdmin public {
        enabled = true;
    }
    
    function disable() onlyAdmin public {
        enabled = false;
    }
    
    function setWeight(uint newWeight) onlyAdmin public {
        require(newWeight > 0 && newWeight <= 1000000);
        weight = uint32(newWeight);
    }
    
    function setFee(uint newFee) onlyAdmin public {
        require(newFee >= 0 && newFee <= 1000000);
        fee = uint32(newFee);
    }
    
    function setIssuedSupplyRatio(uint newRatio) onlyAdmin public {
        require(newRatio > 0);
        issuedSupplyRatio = uint32(newRatio);
    }
    
    function setVirtualReserveBalance(uint256 newBalance) onlyAdmin public {
        virtualReserveBalance = newBalance;
    }
    
    function getReserves() public view returns (uint256, uint256) {
        return (tokenContract.balanceOf(this), address(this).balance + virtualReserveBalance);
    }
    
    function getPurchasePrice(uint256 etherAmount) public view returns(uint) {
        uint256 tokenAmount = weightFormula.calculatePurchaseReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            etherAmount
        );
        
        tokenAmount = (tokenAmount - ((tokenAmount * fee) / 1000000));
        
        if (tokenAmount > tokenContract.balanceOf(this)) {
            return tokenContract.balanceOf(this);
        }
        
        return tokenAmount;
    }
    
    function getSaleReturn(uint256 tokenAmount) public view returns(uint) {
        uint256 etherAmount = weightFormula.calculateSaleReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            tokenAmount
        );
        
        etherAmount = (etherAmount - ((etherAmount * fee) / 1000000));
        
        if (etherAmount > address(this).balance) {
            return address(this).balance;
        }
        
        return etherAmount;
    }
    
    function buy(uint minTokens) public payable {
        uint tokenAmount = weightFormula.calculatePurchaseReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            (address(this).balance + virtualReserveBalance) - msg.value,
            weight,
            msg.value
        );
        
        tokenAmount = (tokenAmount - ((tokenAmount * fee) / 1000000));
        
        require(tokenAmount >= minTokens);
        require(tokenContract.balanceOf(this) >= tokenAmount);
        
        collectedFees += (msg.value * fee) / 1000000;
        
        emit Buy(msg.sender, msg.value, tokenAmount);
        tokenContract.transfer(msg.sender, tokenAmount);
    }
    
    function sell(uint tokenAmount, uint minEther) public {
        uint etherAmount = weightFormula.calculateSaleReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            tokenAmount
        );
        
        etherAmount = (etherAmount - ((etherAmount * fee) / 1000000));
        
        require(enabled);
        require(etherAmount >= minEther);
        require(etherAmount <= address(this).balance);
        require(tokenContract.transferFrom(msg.sender, this, tokenAmount));
        
        collectedFees += (etherAmount * fee) / 1000000;
        
        emit Sell(msg.sender, tokenAmount, etherAmount);
        msg.sender.transfer(etherAmount);
    }
    
    function tokenFallback(address from, uint256 value, address to, bytes data) external {
        processSale(value, 0, from);
    }
    
    function processSale(uint tokenAmount, uint minEther, address seller) public {
        uint etherAmount = weightFormula.calculateSaleReturn(
            (tokenContract.totalSupply() / issuedSupplyRatio) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            tokenAmount
        );
        
        etherAmount = (etherAmount - ((etherAmount * fee) / 1000000));
        
        require(enabled);
        require(etherAmount >= minEther);
        require(etherAmount <= address(this).balance);
        require(tokenContract.transferFrom(seller, this, tokenAmount));
        
        collectedFees += (etherAmount * fee) / 1000000;
        
        emit Sell(seller, tokenAmount, etherAmount);
        seller.transfer(etherAmount);
    }
    
    uint256 public virtualReserveBalance;
    uint256 public collectedFees;
}
```