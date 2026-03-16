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

contract ARXCrowdsale is Owned, SafeMath {
    StandardToken public tokenReward;
    string public currentStatus = "";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed sender, uint256 eth, uint256 arx);
    event Refund(address indexed refunder, uint256 value);
    event Burn(address from, uint256 value);

    mapping(address => uint256) balances;
    mapping(address => uint256) userFundValue;

    struct CrowdsaleState {
        bool isCrowdSaleSetup;
        bool areFundsReleasedToBeneficiary;
        bool isCrowdSaleClosed;
        uint256 fundingEndBlock;
        uint256 fundingStartBlock;
        uint256 fundingMaxCapInWei;
        uint256 fundingMinCapInWei;
        uint256 amountRaisedInWei;
        address beneficiaryWallet;
        uint256 tokensRemaining;
        uint256 initialTokenSupply;
        address admin;
    }

    CrowdsaleState public state;

    function ARXCrowdsale() public onlyOwner {
        state.admin = msg.sender;
        currentStatus = "Crowdsale deployed to chain";
    }

    function initialARXSupply() public view returns (uint256) {
        return safeDiv(state.initialTokenSupply, 1 ether);
    }

    function remainingARXSupply() public view returns (uint256) {
        return safeDiv(state.tokensRemaining, 1 ether);
    }

    function setupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32) {
        if (msg.sender == state.admin && !state.isCrowdSaleSetup && state.beneficiaryWallet == address(0)) {
            state.beneficiaryWallet = 0x98DE47A1F7F96500276900925B334E4e54b1caD5;
            tokenReward = StandardToken(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);
            state.fundingMinCapInWei = 30 ether;
            state.initialTokenSupply = 277500000 ether;
            state.amountRaisedInWei = 0;
            state.tokensRemaining = state.initialTokenSupply;
            state.fundingStartBlock = _fundingStartBlock;
            state.fundingEndBlock = _fundingEndBlock;
            state.fundingMaxCapInWei = 4500 ether;
            state.isCrowdSaleSetup = true;
            state.isCrowdSaleClosed = false;
            currentStatus = "Crowdsale is setup";
            return "Crowdsale is setup";
        } else if (msg.sender != state.admin) {
            return "not authorised";
        } else {
            return "campaign cannot be changed";
        }
    }

    function checkPrice() internal view returns (uint256) {
        if (block.number >= 5532293) {
            return 2250;
        } else if (block.number >= 5490292) {
            return 2500;
        } else if (block.number >= 5406291) {
            return 2750;
        } else if (block.number >= 5370290) {
            return 3000;
        } else if (block.number >= 5352289) {
            return 3250;
        } else if (block.number >= 5310289) {
            return 3500;
        } else if (block.number >= 5268288) {
            return 4000;
        } else if (block.number >= 5232287) {
            return 4500;
        } else if (block.number >= state.fundingStartBlock) {
            return 5000;
        }
    }

    function () public payable {
        require(msg.value > 0 && msg.data.length == 0 && block.number <= state.fundingEndBlock && block.number >= state.fundingStartBlock && state.tokensRemaining > 0);

        uint256 rewardTransferAmount = safeMul(msg.value, checkPrice());
        state.amountRaisedInWei = safeAdd(state.amountRaisedInWei, msg.value);
        state.tokensRemaining = safeSub(state.tokensRemaining, rewardTransferAmount);
        tokenReward.transfer(msg.sender, rewardTransferAmount);
        userFundValue[msg.sender] = safeAdd(userFundValue[msg.sender], msg.value);
        Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
        require(state.areFundsReleasedToBeneficiary && state.amountRaisedInWei >= state.fundingMinCapInWei);
        state.beneficiaryWallet.transfer(_amount);
        Transfer(this, state.beneficiaryWallet, _amount);
    }

    function checkGoalReached() public onlyOwner {
        require(state.isCrowdSaleSetup);

        if (state.amountRaisedInWei < state.fundingMinCapInWei && block.number <= state.fundingEndBlock && block.number >= state.fundingStartBlock) {
            state.areFundsReleasedToBeneficiary = false;
            state.isCrowdSaleClosed = false;
            currentStatus = "In progress (Eth < Softcap)";
        } else if (state.amountRaisedInWei < state.fundingMinCapInWei && block.number < state.fundingStartBlock) {
            state.areFundsReleasedToBeneficiary = false;
            state.isCrowdSaleClosed = false;
            currentStatus = "Crowdsale is setup";
        } else if (state.amountRaisedInWei < state.fundingMinCapInWei && block.number > state.fundingEndBlock) {
            state.areFundsReleasedToBeneficiary = false;
            state.isCrowdSaleClosed = true;
            currentStatus = "Unsuccessful (Eth < Softcap)";
        } else if (state.amountRaisedInWei >= state.fundingMinCapInWei && state.tokensRemaining == 0) {
            state.areFundsReleasedToBeneficiary = true;
            state.isCrowdSaleClosed = true;
            currentStatus = "Successful (ARX >= Hardcap)!";
        } else if (state.amountRaisedInWei >= state.fundingMinCapInWei && block.number > state.fundingEndBlock && state.tokensRemaining > 0) {
            state.areFundsReleasedToBeneficiary = true;
            state.isCrowdSaleClosed = true;
            currentStatus = "Successful (Eth >= Softcap)!";
        } else if (state.amountRaisedInWei >= state.fundingMinCapInWei && state.tokensRemaining > 0 && block.number <= state.fundingEndBlock) {
            state.areFundsReleasedToBeneficiary = true;
            state.isCrowdSaleClosed = false;
            currentStatus = "In progress (Eth >= Softcap)!";
        }
    }

    function refund() public {
        require(state.amountRaisedInWei < state.fundingMinCapInWei && state.isCrowdSaleClosed && block.number > state.fundingEndBlock && userFundValue[msg.sender] > 0);

        uint256 ethRefund = userFundValue[msg.sender];
        balances[msg.sender] = 0;
        userFundValue[msg.sender] = 0;
        Burn(msg.sender, userFundValue[msg.sender]);
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }
}