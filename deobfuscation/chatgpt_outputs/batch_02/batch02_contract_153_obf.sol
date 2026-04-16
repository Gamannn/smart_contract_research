pragma solidity ^0.4.18;

contract UniversityFund {
    address public owner;
    uint256 public constant MINIMUM_CONTRIBUTION = 0.001 ether;
    uint256[8] public contributions = [1, 1, 1, 1, 1, 1, 1, 1];

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function UniversityFund() public {
        owner = msg.sender;
    }

    function contribute(uint8 universityIndex) public payable {
        require(msg.value >= MINIMUM_CONTRIBUTION);
        uint256 contributionAmount = msg.value / MINIMUM_CONTRIBUTION;
        contributions[universityIndex] += contributionAmount;
    }

    function withdraw(address recipient) public onlyOwner {
        if (recipient == address(0)) {
            owner.transfer(this.balance);
        } else {
            recipient.transfer(this.balance);
        }
    }

    function updateOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function getContributions() public view returns (uint256[8]) {
        return contributions;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [0, 1000000000000000, 7, 1];
    string[] public _string_constant = [
        "UniversityFund",
        "BrownColumbiaCornellDartmouthHarvardPennPrincetonYale"
    ];
}