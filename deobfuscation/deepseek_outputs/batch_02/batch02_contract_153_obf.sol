```solidity
pragma solidity ^0.4.18;

contract IvyLeagueDonation {
    address public owner;
    string public contractName = "IvyLeagueDonation";
    string public universities = "BrownColumbiaCornellDartmouthHarvardPennPrincetonYale";
    uint256 public donationAmount = 0.001 ether;
    
    uint256[8] public universityDonations = [1, 1, 1, 1, 1, 1, 1, 1];
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function IvyLeagueDonation() public {
        owner = msg.sender;
    }
    
    function withdraw(address recipient) public onlyOwner {
        performWithdrawal(recipient);
    }
    
    function donate(uint8 universityIndex) public payable {
        require(msg.value >= donationAmount);
        uint256 donationMultiplier = msg.value / donationAmount;
        universityDonations[universityIndex] += donationMultiplier;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    function getUniversityDonations() public view returns (uint256[8]) {
        return universityDonations;
    }
    
    function performWithdrawal(address recipient) private {
        if (recipient == address(0)) {
            owner.transfer(this.balance);
        } else {
            recipient.transfer(this.balance);
        }
    }
}
```