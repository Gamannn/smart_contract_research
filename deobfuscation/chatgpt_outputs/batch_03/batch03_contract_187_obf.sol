pragma solidity ^0.4.25;

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
        return a / b;
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

contract AdvertisementContract {
    using SafeMath for uint256;

    event NewAd(
        address indexed advertiser,
        uint256 amount,
        string title,
        string description,
        uint256 duration,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == contractData.owner);
        _;
    }

    struct ContractData {
        address owner;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 adDuration;
        uint256 lastAdTimestamp;
        string adTitle;
        string adDescription;
    }

    ContractData contractData = ContractData(
        0x2E26a4ac59094DA46a0D8d65D90A7F7B51E5E69A,
        50000000000000000,
        150000000000000000,
        0,
        0,
        "",
        ""
    );

    constructor() public {}

    function withdraw() public onlyOwner {
        contractData.owner.transfer(address(this).balance);
    }

    function setMinAmount(uint256 minAmount) public onlyOwner {
        contractData.minAmount = minAmount;
    }

    function setMaxAmount(uint256 maxAmount) public onlyOwner {
        contractData.maxAmount = maxAmount;
    }

    function createAd(string title, string description) public payable {
        require(msg.value >= contractData.minAmount);
        require(block.timestamp > contractData.lastAdTimestamp.add(contractData.adDuration));

        if (msg.value >= contractData.maxAmount) {
            contractData.adDuration = 2592000; // 30 days
        } else {
            contractData.adDuration = 604800; // 7 days
        }

        contractData.adTitle = title;
        contractData.adDescription = description;
        contractData.lastAdTimestamp = block.timestamp;

        emit NewAd(msg.sender, msg.value, contractData.adTitle, contractData.adDescription, contractData.adDuration, contractData.lastAdTimestamp);
    }

    function getTimeUntilNextAd() public view returns (uint256) {
        return contractData.lastAdTimestamp.add(contractData.adDuration).sub(block.timestamp);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}