pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AdvertisementBoard {
    using SafeMath for uint256;

    event newAd(
        address indexed advertiser,
        uint256 amount,
        string title,
        string description,
        uint256 duration,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == data.owner);
        _;
    }

    constructor() public {
        data.minPayment = 50000000000000000;
        data.premiumThreshold = 150000000000000000;
        data.owner = 0x2E26a4ac59094DA46a0D8d65D90A7F7B51E5E69A;
    }

    function withdraw() public onlyOwner {
        data.owner.transfer(address(this).balance);
    }

    function setMinPayment(uint256 _minPayment) public onlyOwner {
        data.minPayment = _minPayment;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) public onlyOwner {
        data.premiumThreshold = _premiumThreshold;
    }

    function placeAd(string _title, string _description) public payable {
        require(msg.value >= data.minPayment);
        require(block.timestamp > data.lastAdTimestamp.add(data.duration));

        if (msg.value >= data.premiumThreshold) {
            data.duration = 2592000; // 30 days
        } else {
            data.duration = 604800; // 7 days
        }

        data.title = _title;
        data.description = _description;
        data.lastAdTimestamp = block.timestamp;

        emit newAd(
            msg.sender,
            msg.value,
            data.title,
            data.description,
            data.duration,
            data.lastAdTimestamp
        );
    }

    function getNextAvailableTime() public view returns (uint nextTime) {
        return data.lastAdTimestamp.add(data.duration);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    struct Data {
        address owner;
        uint256 premiumThreshold;
        uint256 minPayment;
        uint256 duration;
        uint256 lastAdTimestamp;
        string description;
        string title;
    }

    Data data = Data(address(0), 0, 0, 0, 0, "", "");
}