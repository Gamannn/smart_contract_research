```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }
    
    function require(bool condition) internal pure {
        if (!condition) revert();
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Crowdsale is Ownable, SafeMath {
    address public adminWallet = owner;
    address public tokenReward;
    address public beneficiaryWallet;
    
    uint256 private initialEPXSupply;
    uint256 private initialTokenSupply;
    
    event Buy(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event Refund(address indexed contributor, uint256 ethAmount);
    event Burn(address burner, uint256 tokenAmount);
    
    mapping(address => uint256) public balancesArray;
    mapping(address => uint256) public ethContributed;
    
    bool public isCrowdSaleSetup = false;
    bool public isCrowdSaleClosed = false;
    bool public areFundsReleasedToBeneficiary = false;
    
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    
    string public CurrentStatus = "";
    
    uint256 public fundingMinCapInWei;
    uint256 public amountRaisedInWei;
    
    function Crowdsale() public onlyOwner {
        adminWallet = msg.sender;
        CurrentStatus = "Crowdsale deployed on chain";
    }
    
    function initialEPXSupply() public view returns (uint256) {
        return safeDiv(initialEPXSupply, 10000);
    }
    
    function initialTokenSupply() public view returns (uint256) {
        return safeDiv(initialTokenSupply, 10000);
    }
    
    function setupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32) {
        if ((msg.sender == adminWallet) && (!isCrowdSaleSetup) && (!(amountRaisedInWei > 0))) {
            tokenReward = address(0x7A29e1343c6a107ce78199F1b3a1d2952efd77bA);
            beneficiaryWallet = address(0x35BAA72038F127f9f8C8f9B491049f64f377914d);
            fundingMinCapInWei = 10000000000000000000;
            amountRaisedInWei = 0;
            initialEPXSupply = 15000000000;
            initialTokenSupply = initialEPXSupply;
            fundingStartBlock = _fundingStartBlock;
            fundingEndBlock = _fundingEndBlock;
            isCrowdSaleSetup = true;
            isCrowdSaleClosed = false;
            CurrentStatus = "Crowdsale is setup";
            return "Crowdsale is setup";
        }
        if (msg.sender != adminWallet) {
            return "not authorised";
        } else {
            return "campaign cannot be changed";
        }
    }
    
    function getCurrentRate() internal view returns (uint256) {
        if (block.number >= fundingStartBlock + 177534) {
            return 8500;
        } else if (block.number >= fundingStartBlock + 124274) {
            return 9250;
        } else if (block.number >= fundingStartBlock) {
            return 10000;
        }
    }
    
    function () public payable {
        require(!(msg.value == 0) && (msg.data.length == 0) && (block.number <= fundingEndBlock) && (block.number >= fundingStartBlock) && (initialTokenSupply > 0));
        
        uint256 tokenAmount = 0;
        amountRaisedInWei = safeAdd(amountRaisedInWei, msg.value);
        tokenAmount = safeDiv(safeMul(msg.value, getCurrentRate()), 100000000000000);
        
        ERC20(tokenReward).transfer(msg.sender, tokenAmount);
        ethContributed[msg.sender] = safeAdd(ethContributed[msg.sender], msg.value);
        Buy(msg.sender, msg.value, tokenAmount);
    }
    
    function beneficiaryMultiSigWithdraw(uint256 amount) public onlyOwner {
        require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
        ERC20(tokenReward).transfer(beneficiaryWallet, amount);
        Transfer(this, beneficiaryWallet, amount);
    }
    
    function checkGoalReached() public onlyOwner returns (bytes32) {
        if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) {
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            CurrentStatus = "In progress (Eth < Softcap)";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) {
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            CurrentStatus = "Crowdsale not started";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) {
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = true;
            CurrentStatus = "Unsuccessful (Eth < Softcap)";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (initialTokenSupply == 0)) {
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            CurrentStatus = "Successful (EPX >= Hardcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock)) {
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            CurrentStatus = "Successful (Eth >= Softcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (initialTokenSupply > 0) && (block.number <= fundingEndBlock)) {
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = false;
            CurrentStatus = "In progress (Eth >= Softcap)!";
        }
    }
    
    function refund() public {
        require((amountRaisedInWei < fundingMinCapInWei) && (isCrowdSaleClosed) && (block.number > fundingEndBlock) && (ethContributed[msg.sender] > 0));
        
        uint256 ethRefund = ethContributed[msg.sender];
        balancesArray[msg.sender] = 0;
        ethContributed[msg.sender] = 0;
        Burn(msg.sender, ethContributed[msg.sender]);
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }
}
```