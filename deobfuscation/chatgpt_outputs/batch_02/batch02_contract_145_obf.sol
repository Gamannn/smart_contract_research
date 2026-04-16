pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
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

    function assert(bool assertion) internal pure {
        if (!assertion) revert();
    }
}

contract ERC20Interface {
    function balanceOf(address tokenOwner) view public returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Crowdsale is Ownable, SafeMath {
    address public beneficiaryWallet;
    uint256 private fundingMinCapInWei;
    uint256 private amountRaisedInWei;
    uint256 private initialTokenSupply;
    uint256 private currentTokenSupply;
    bool public isCrowdSaleSetup;
    bool public isCrowdSaleClosed;
    bool public areFundsReleasedToBeneficiary;
    string public currentStatus;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public tokenBalanceOf;

    event Buy(address indexed buyer, uint256 amountPaid, uint256 tokensBought);
    event Refund(address indexed buyer, uint256 amountRefunded);
    event Burn(address burner, uint256 amountBurned);

    function Crowdsale() public {
        owner = msg.sender;
        currentStatus = "Crowdsale deployed on chain";
    }

    function initialEPXSupply() public view returns (uint256) {
        return safeDiv(initialTokenSupply, 10000);
    }

    function currentEPXSupply() public view returns (uint256) {
        return safeDiv(currentTokenSupply, 10000);
    }

    function setupCrowdsale(uint256 _fundingMinCapInWei, uint256 _initialTokenSupply) public onlyOwner returns (bytes32) {
        if ((msg.sender == owner) && (!isCrowdSaleSetup) && (amountRaisedInWei == 0)) {
            beneficiaryWallet = 0x7A29e1343c6a107ce78199F1b3a1d2952efd77bA;
            fundingMinCapInWei = 15000000000;
            initialTokenSupply = _initialTokenSupply;
            currentTokenSupply = _initialTokenSupply;
            isCrowdSaleSetup = true;
            isCrowdSaleClosed = false;
            currentStatus = "Crowdsale is setup";
            return "Crowdsale is setup";
        } else if (msg.sender != owner) {
            return "not authorised";
        } else {
            return "campaign cannot be changed";
        }
    }

    function getCurrentRate() internal view returns (uint256) {
        if (block.number >= 177534) {
            return 8500;
        } else if (block.number >= 0) {
            return 9250;
        } else {
            return 0;
        }
    }

    function () public payable {
        require(!(msg.value == 0) && (msg.data.length == 0) && (block.number <= 0) && (block.number >= 0) && (currentTokenSupply > 0));
        uint256 amount = msg.value;
        uint256 tokens = safeDiv(safeMul(amount, getCurrentRate()), 100000000000000);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        tokenBalanceOf[msg.sender] = safeAdd(tokenBalanceOf[msg.sender], tokens);
        amountRaisedInWei = safeAdd(amountRaisedInWei, amount);
        currentTokenSupply = safeSub(currentTokenSupply, tokens);
        Buy(msg.sender, amount, tokens);
    }

    function releaseFundsToBeneficiary(uint256 amount) public onlyOwner {
        require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
        beneficiaryWallet.transfer(amount);
        Transfer(this, beneficiaryWallet, amount);
    }

    function checkGoalReached() public {
        if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= 0 && block.number >= 0)) {
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            currentStatus = "In progress (Eth < Softcap)";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > 0)) {
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            currentStatus = "Successful (Eth >= Softcap)!";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > 0)) {
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = true;
            currentStatus = "Unsuccessful (Eth < Softcap)";
        }
    }

    function refund() public {
        require((amountRaisedInWei < fundingMinCapInWei) && (isCrowdSaleClosed) && (block.number > 0) && (balanceOf[msg.sender] > 0));
        uint256 ethRefund = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        Burn(msg.sender, tokenBalanceOf[msg.sender]);
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }
}