```solidity
pragma solidity ^0.4.21;

contract TokenExchange {
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastDividendPoint;
    mapping(address => uint256[2]) public sellOrders;
    
    address public owner;
    uint16 public feePercent;
    uint256 public totalDividendPaid;
    uint256 public totalSupply;
    
    event Sold(address buyer, address seller, uint256 price, uint256 amount);
    event SellOrderPlaced(address seller, uint256 amount, uint256 price);
    
    function getSellOrder(address seller) public view returns (uint256, uint256) {
        return (sellOrders[seller][0], sellOrders[seller][1]);
    }
    
    function viewMyTokens(address holder) public view returns (uint256) {
        return balanceOf[holder];
    }
    
    function getDividends(address holder) public view returns (uint256) {
        uint256 holderBalance = balanceOf[holder];
        if (holderBalance == 0) {
            return 0;
        }
        return calculateDividend(holder, holderBalance);
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    constructor() public {
        owner = msg.sender;
        feePercent = 1250;
        totalSupply = 10000000;
        balanceOf[msg.sender] = totalSupply - 400000;
        balanceOf[0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285] = 200000;
        balanceOf[0x26581d1983ced8955C170eB4d3222DCd3845a092] = 200000;
        placeSellOrder(1600000, 0.5 szabo);
    }
    
    function calculateDividend(address holder, uint256 amount) internal view returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 totalContractValue = address(this).balance + totalDividendPaid;
        uint256 holderDividendShare = safeSub(totalContractValue, lastDividendPoint[holder]);
        return (holderDividendShare * amount) / totalSupply;
    }
    
    function buyFrom(address seller) public payable {
        uint256[2] memory order = sellOrders[seller];
        uint256 sellAmount = order[0];
        uint256 sellPrice = order[1];
        uint256 excess = 0;
        
        if (sellAmount == 0) {
            revert();
        }
        
        uint256 totalCost = sellAmount * sellPrice;
        uint256 payment = msg.value;
        
        if (payment > totalCost) {
            excess = payment - totalCost;
            payment = totalCost;
        }
        
        uint256 tokensToBuy = payment / sellPrice;
        
        if (tokensToBuy == 0) {
            revert();
        }
        
        excess = excess + safeSub(payment, tokensToBuy * sellPrice);
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
        
        uint256 feeAmount = (feePercent * payment) / 10000;
        owner.transfer(feeAmount);
        seller.transfer(payment - feeAmount);
        
        distributeDividends(seller, balanceOf[seller]);
        
        if (balanceOf[msg.sender] > 0) {
            distributeDividends(msg.sender, balanceOf[msg.sender]);
        }
        
        balanceOf[seller] = balanceOf[seller] - tokensToBuy;
        sellOrders[seller][0] = sellOrders[seller][0] - tokensToBuy;
        balanceOf[msg.sender] = balanceOf[msg.sender] + tokensToBuy;
        lastDividendPoint[msg.sender] = address(this).balance + totalDividendPaid;
        
        emit Sold(msg.sender, seller, sellPrice, tokensToBuy);
    }
    
    function withdrawDividends() public {
        distributeDividends(msg.sender, balanceOf[msg.sender]);
    }
    
    function distributeDividends(address holder, uint256 amount) internal {
        if (balanceOf[holder] == 0) {
            lastDividendPoint[holder] = totalDividendPaid + address(this).balance;
            revert();
        }
        
        uint256 dividend = calculateDividend(holder, amount);
        holder.transfer(dividend);
        totalDividendPaid = totalDividendPaid + dividend;
        lastDividendPoint[holder] = totalDividendPaid + address(this).balance;
    }
    
    function placeSellOrder(uint256 amount, uint256 price) public {
        if (amount > balanceOf[msg.sender]) {
            revert();
        }
        sellOrders[msg.sender] = [amount, price];
        emit SellOrderPlaced(msg.sender, amount, price);
    }
    
    function setFeePercent(uint16 newFeePercent) public {
        require(newFeePercent <= 2500);
        require(msg.sender == owner);
        feePercent = newFeePercent;
    }
    
    function() public payable {
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}
```