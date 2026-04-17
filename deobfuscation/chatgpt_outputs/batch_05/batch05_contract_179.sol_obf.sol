```solidity
pragma solidity ^0.4.13;

contract TokenInterface {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract BountyContract {
    mapping (address => uint256) public balances;
    uint256 public buyBounty;
    uint256 public withdrawBounty;
    bool public isBountyActive;
    uint256 public contractEthValue;
    bool public isContractActive;
    uint256 public earliestBuyTime = 1504188000;
    uint256 public ethCap = 30000 ether;
    address public owner = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
    address public tokenAddress;
    TokenInterface public token;

    function BountyContract(address _tokenAddress) {
        require(msg.sender == owner);
        require(tokenAddress == 0x0);
        tokenAddress = _tokenAddress;
        token = TokenInterface(_tokenAddress);
    }

    function activateBounty(string secret) {
        require(msg.sender == owner || sha3(secret) == 0x1bef4b8a66d06a387481787c0e4bf01dfa28c25e);
        uint256 bountyAmount = buyBounty;
        buyBounty = 0;
        isBountyActive = true;
        msg.sender.transfer(bountyAmount);
    }

    function withdraw(address recipient) {
        require(isBountyActive || now > earliestBuyTime + 1 hours);
        if (balances[recipient] == 0) return;
        if (!isBountyActive) {
            uint256 amount = balances[recipient];
            balances[recipient] = 0;
            recipient.transfer(amount);
        } else {
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance != 0);
            uint256 payout = (balances[recipient] * tokenBalance) / contractEthValue;
            contractEthValue -= balances[recipient];
            balances[recipient] = 0;
            uint256 fee = payout / 100;
            require(token.transfer(owner, fee));
            require(token.transfer(recipient, payout - fee));
        }
        uint256 bountyFee = withdrawBounty / 100;
        withdrawBounty -= bountyFee;
    }

    function deposit() payable {
        require(msg.sender == owner);
        buyBounty += msg.value;
    }

    function addToWithdrawBounty() payable {
        require(msg.sender == owner);
        withdrawBounty += msg.value;
    }

    function activateContract() {
        if (isBountyActive) return;
        if (now < earliestBuyTime) return;
        if (isContractActive) return;
        require(tokenAddress != 0x0);
        isBountyActive = true;
        uint256 bountyAmount = buyBounty;
        buyBounty = 0;
        contractEthValue = this.balance - (bountyAmount + withdrawBounty);
        require(tokenAddress.call.value(contractEthValue)());
        msg.sender.transfer(bountyAmount);
    }

    function () payable {
        require(!isContractActive);
        require(!isBountyActive);
        require(this.balance < ethCap);
        balances[msg.sender] += msg.value;
    }
}
```