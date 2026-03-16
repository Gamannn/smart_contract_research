pragma solidity ^0.4.18;

contract Owned {
    address public owner;

    function Owned() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        safeAssert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        safeAssert(b > 0);
        uint256 c = a / b;
        safeAssert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        safeAssert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        safeAssert(c >= a && c >= b);
        return c;
    }

    function safeAssert(bool assertion) internal pure {
        if (!assertion) revert();
    }
}

contract StandardToken is Owned, SafeMath {
    function balanceOf(address who) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract EPXCrowdsale is Owned, SafeMath {
    StandardToken public tokenReward;
    string public currentStatus = "";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed sender, uint256 eth, uint256 epx);
    event Refund(address indexed refunder, uint256 value);
    event Burn(address from, uint256 value);

    mapping(address => uint256) balances;
    mapping(address => uint256) userEPXFundValue;

    struct CrowdsaleState {
        bool isCrowdSaleSetup;
        bool areFundsReleasedToBeneficiary;
        bool isCrowdSaleClosed;
        uint256 fundingEndBlock;
        uint256 fundingStartBlock;
        uint256 fundingMinCapInWei;
        uint256 amountRaisedInWei;
        address beneficiaryWallet;
        uint256 tokensRemaining;
        uint256 initialTokenSupply;
        address crowdsaleOwner;
    }

    CrowdsaleState public crowdsaleState;

    function EPXCrowdsale() public onlyOwner {
        crowdsaleState.crowdsaleOwner = msg.sender;
        currentStatus = "Crowdsale deployed to chain";
    }

    function initialEPXSupply() public view returns (uint256) {
        return safeDiv(crowdsaleState.initialTokenSupply, 10000);
    }

    function remainingEPXSupply() public view returns (uint256) {
        return safeDiv(crowdsaleState.tokensRemaining, 10000);
    }

    function setupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32) {
        if (msg.sender == crowdsaleState.crowdsaleOwner && !crowdsaleState.isCrowdSaleSetup && crowdsaleState.beneficiaryWallet == address(0)) {
            crowdsaleState.beneficiaryWallet = 0x7A29e1343c6a107ce78199F1b3a1d2952efd77bA;
            tokenReward = StandardToken(0x35BAA72038F127f9f8C8f9B491049f64f377914d);
            crowdsaleState.fundingMinCapInWei = 30 ether;
            crowdsaleState.amountRaisedInWei = 0;
            crowdsaleState.initialTokenSupply = 200000000000;
            crowdsaleState.tokensRemaining = crowdsaleState.initialTokenSupply;
            crowdsaleState.fundingStartBlock = _fundingStartBlock;
            crowdsaleState.fundingEndBlock = _fundingEndBlock;
            crowdsaleState.isCrowdSaleSetup = true;
            crowdsaleState.isCrowdSaleClosed = false;
            currentStatus = "Crowdsale is setup";
            return "Crowdsale is setup";
        } else if (msg.sender != crowdsaleState.crowdsaleOwner) {
            return "not authorised";
        } else {
            return "campaign cannot be changed";
        }
    }

    function checkPrice() internal view returns (uint256) {
        if (block.number >= crowdsaleState.fundingStartBlock + 177534) {
            return 7600;
        } else if (block.number >= crowdsaleState.fundingStartBlock + 124274) {
            return 8200;
        } else if (block.number >= crowdsaleState.fundingStartBlock) {
            return 8800;
        }
    }

    function () public payable {
        require(msg.value != 0 && msg.data.length == 0 && block.number <= crowdsaleState.fundingEndBlock && block.number >= crowdsaleState.fundingStartBlock && crowdsaleState.tokensRemaining > 0);

        uint256 rewardTransferAmount = 0;
        crowdsaleState.amountRaisedInWei = safeAdd(crowdsaleState.amountRaisedInWei, msg.value);
        rewardTransferAmount = safeMul(msg.value, checkPrice()) / 100000000000000;
        crowdsaleState.tokensRemaining = safeSub(crowdsaleState.tokensRemaining, rewardTransferAmount);
        tokenReward.transfer(msg.sender, rewardTransferAmount);
        userEPXFundValue[msg.sender] = safeAdd(userEPXFundValue[msg.sender], msg.value);
        Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
        require(crowdsaleState.areFundsReleasedToBeneficiary && crowdsaleState.amountRaisedInWei >= crowdsaleState.fundingMinCapInWei);
        crowdsaleState.beneficiaryWallet.transfer(_amount);
        Transfer(this, crowdsaleState.beneficiaryWallet, _amount);
    }

    function checkGoalReached() public onlyOwner {
        require(crowdsaleState.isCrowdSaleSetup);

        if (crowdsaleState.amountRaisedInWei < crowdsaleState.fundingMinCapInWei && block.number <= crowdsaleState.fundingEndBlock && block.number >= crowdsaleState.fundingStartBlock) {
            crowdsaleState.areFundsReleasedToBeneficiary = false;
            crowdsaleState.isCrowdSaleClosed = false;
            currentStatus = "In progress (Eth < Softcap)";
        } else if (crowdsaleState.amountRaisedInWei < crowdsaleState.fundingMinCapInWei && block.number < crowdsaleState.fundingStartBlock) {
            crowdsaleState.areFundsReleasedToBeneficiary = false;
            crowdsaleState.isCrowdSaleClosed = false;
            currentStatus = "Crowdsale is setup";
        } else if (crowdsaleState.amountRaisedInWei < crowdsaleState.fundingMinCapInWei && block.number > crowdsaleState.fundingEndBlock) {
            crowdsaleState.areFundsReleasedToBeneficiary = false;
            crowdsaleState.isCrowdSaleClosed = true;
            currentStatus = "Unsuccessful (Eth < Softcap)";
        } else if (crowdsaleState.amountRaisedInWei >= crowdsaleState.fundingMinCapInWei && crowdsaleState.tokensRemaining == 0) {
            crowdsaleState.areFundsReleasedToBeneficiary = true;
            crowdsaleState.isCrowdSaleClosed = true;
            currentStatus = "Successful (EPX >= Hardcap)!";
        } else if (crowdsaleState.amountRaisedInWei >= crowdsaleState.fundingMinCapInWei && block.number > crowdsaleState.fundingEndBlock && crowdsaleState.tokensRemaining > 0) {
            crowdsaleState.areFundsReleasedToBeneficiary = true;
            crowdsaleState.isCrowdSaleClosed = true;
            currentStatus = "Successful (Eth >= Softcap)!";
        } else if (crowdsaleState.amountRaisedInWei >= crowdsaleState.fundingMinCapInWei && crowdsaleState.tokensRemaining > 0 && block.number <= crowdsaleState.fundingEndBlock) {
            crowdsaleState.areFundsReleasedToBeneficiary = true;
            crowdsaleState.isCrowdSaleClosed = false;
            currentStatus = "In progress (Eth >= Softcap)!";
        }
    }

    function refund() public {
        require(crowdsaleState.amountRaisedInWei < crowdsaleState.fundingMinCapInWei && crowdsaleState.isCrowdSaleClosed && block.number > crowdsaleState.fundingEndBlock && userEPXFundValue[msg.sender] > 0);

        uint256 ethRefund = userEPXFundValue[msg.sender];
        balances[msg.sender] = 0;
        userEPXFundValue[msg.sender] = 0;
        Burn(msg.sender, userEPXFundValue[msg.sender]);
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }
}