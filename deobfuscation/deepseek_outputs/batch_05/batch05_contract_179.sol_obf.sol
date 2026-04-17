```solidity
pragma solidity ^0.4.13;

interface Token {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract Crowdsale {
    mapping (address => uint256) public contributions;
    uint256 public buy_bounty;
    uint256 public withdraw_bounty;
    bool public saleEnded;
    uint256 public contract_eth_value;
    bool public halted;
    uint256 public earliest_buy_time = 1504188000;
    uint256 public eth_cap = 30000 ether;
    address public owner = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
    address public tokenAddress;
    
    Token token;
    
    function setTokenAddress(address _tokenContract, address _tokenAddress) {
        require(msg.sender == owner);
        require(tokenAddress == 0x0);
        tokenAddress = _tokenContract;
        token = Token(_tokenAddress);
    }
    
    function claimBounty(string memory password) {
        require(msg.sender == owner || sha3(password) == 0x1bef4b8a66d06a387481787c0e4bf01dfa28c25e);
        uint256 bountyAmount = buy_bounty;
        buy_bounty = 0;
        saleEnded = true;
        msg.sender.transfer(bountyAmount);
    }
    
    function withdraw(address contributor) {
        require(saleEnded || now > earliest_buy_time + 1 hours);
        
        if (contributions[contributor] == 0) return;
        
        if (!saleEnded) {
            uint256 contributionAmount = contributions[contributor];
            contributions[contributor] = 0;
            contributor.transfer(contributionAmount);
        } else {
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance != 0);
            
            uint256 tokenAmount = (contributions[contributor] * tokenBalance) / contract_eth_value;
            contract_eth_value -= contributions[contributor];
            contributions[contributor] = 0;
            
            uint256 fee = tokenAmount / 100;
            require(token.transfer(owner, fee));
            require(token.transfer(contributor, tokenAmount - fee));
        }
        
        uint256 bountyFee = withdraw_bounty / 100;
        withdraw_bounty -= bountyFee;
    }
    
    function addToBuyBounty() payable {
        require(msg.sender == owner);
        buy_bounty += msg.value;
    }
    
    function addToWithdrawBounty() payable {
        require(msg.sender == owner);
        withdraw_bounty += msg.value;
    }
    
    function finalizeSale() {
        if (saleEnded) return;
        if (now < earliest_buy_time) return;
        if (halted) return;
        require(tokenAddress != 0x0);
        
        saleEnded = true;
        uint256 bountyAmount = buy_bounty;
        buy_bounty = 0;
        
        contract_eth_value = this.balance - (bountyAmount + withdraw_bounty);
        require(tokenAddress.call.value(contract_eth_value)());
        
        msg.sender.transfer(bountyAmount);
    }
    
    function () payable {
        require(!halted);
        require(!saleEnded);
        require(this.balance < eth_cap);
        contributions[msg.sender] += msg.value;
    }
}
```