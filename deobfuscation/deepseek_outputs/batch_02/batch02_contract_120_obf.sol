```solidity
pragma solidity ^0.4.18;

contract WineMarket {
    address public vineyardAddress;
    uint256 public marketWine;
    address public ceoAddress;
    address public ceoWallet;
    bool public initialized;
    
    mapping(address => uint256) public wineBalance;
    mapping(address => uint256) public lastDivPoints;
    
    VineyardInterface vineyardContract;
    
    modifier onlyInitialized() {
        require(initialized);
        _;
    }
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
    function WineMarket(address _ceoAddress) public {
        require(_ceoAddress != address(0));
        ceoAddress = msg.sender;
        ceoWallet = _ceoAddress;
        vineyardContract = VineyardInterface(0x66593d57B26Ed56Fd7881a016fcd0AF66636A9F0);
    }
    
    function transferWalletOwnership(address newCEO) public onlyCEO {
        require(newCEO != address(0));
        ceoWallet = newCEO;
    }
    
    function withdrawDividends() onlyInitialized public {
        require(vineyardContract.balanceOf(msg.sender) > lastDivPoints[msg.sender]);
        uint256 dividends = SafeMath.sub(vineyardContract.balanceOf(msg.sender), lastDivPoints[msg.sender]);
        wineBalance[msg.sender] = SafeMath.add(wineBalance[msg.sender], dividends);
        lastDivPoints[msg.sender] = SafeMath.add(lastDivPoints[msg.sender], dividends);
    }
    
    function sellWine(uint256 amount) onlyInitialized public returns(uint256) {
        require(wineBalance[msg.sender] > 0);
        require(amount <= wineBalance[msg.sender]);
        wineBalance[msg.sender] = SafeMath.sub(wineBalance[msg.sender], amount);
        return amount;
    }
    
    function buyWine(uint256 amount) onlyInitialized public {
        require(amount > 0);
        uint256 currentWine = wineBalance[msg.sender];
        uint256 wineToBuy = amount;
        
        if (amount > currentWine) {
            wineToBuy = currentWine;
        }
        
        if (wineToBuy > marketWine) {
            wineToBuy = marketWine;
        }
        
        uint256 wineValue = calculateWineBuyPrice(wineToBuy);
        uint256 devFee = calculateDevFee(wineValue);
        
        wineBalance[msg.sender] = SafeMath.sub(currentWine, wineToBuy);
        marketWine = SafeMath.sub(marketWine, wineToBuy);
        
        ceoWallet.transfer(devFee);
        msg.sender.transfer(SafeMath.sub(wineValue, devFee));
    }
    
    function reinvest() onlyInitialized public payable {
        require(msg.value <= SafeMath.sub(this.balance, msg.value));
        
        uint256 devFee = calculateDevFee(msg.value);
        uint256 taxedEther = SafeMath.sub(msg.value, devFee);
        uint256 wineBought = calculateWineBuy(taxedEther, SafeMath.sub(this.balance, taxedEther));
        
        marketWine = SafeMath.add(marketWine, wineBought);
        ceoWallet.transfer(devFee);
        wineBalance[msg.sender] = SafeMath.add(wineBalance[msg.sender], wineBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public pure returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(SafeMath.mul(10000, bs), 
            SafeMath.add(
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(10000, rs), 
                        SafeMath.mul(5000, rt)
                    ), 
                    rt
                ), 
                5000
            )), 
            10000
        );
    }
    
    function calculateWineSell(uint256 wine, uint256 marketWineAmount) public view returns(uint256) {
        return calculateTrade(wine, marketWineAmount, this.balance);
    }
    
    function calculateWineBuyPrice(uint256 wine) public view returns(uint256) {
        return calculateTrade(wine, marketWine, this.balance);
    }
    
    function calculateWineBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketWine);
    }
    
    function calculateWineBuySimple(uint256 eth) public view returns(uint256) {
        return calculateWineBuy(eth, this.balance);
    }
    
    function calculateDevFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 3), 100);
    }
    
    function seedMarket(uint256 initialWine) public payable {
        require(marketWine == 0);
        require(ceoAddress == msg.sender);
        initialized = true;
        marketWine = initialWine;
    }
    
    function getBalance() public view returns(uint256) {
        return this.balance;
    }
    
    function getMyWine() public view returns(uint256) {
        return SafeMath.add(
            SafeMath.sub(
                vineyardContract.balanceOf(msg.sender),
                lastDivPoints[msg.sender]
            ),
            wineBalance[msg.sender]
        );
    }
    
    function getMyLastDivPoints() public view returns(uint256) {
        return lastDivPoints[msg.sender];
    }
    
    function getMyWineBalance() public view returns(uint256) {
        return wineBalance[msg.sender];
    }
}

interface VineyardInterface {
    function balanceOf(address) public returns (uint256);
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
```