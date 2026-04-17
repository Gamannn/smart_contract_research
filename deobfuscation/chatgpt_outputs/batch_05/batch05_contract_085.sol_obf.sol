```solidity
pragma solidity ^0.4.19;

contract Lottery {
    address public owner;
    uint public ticketPrice;
    uint public maxTickets;
    string public status;
    uint public currentRound;
    address public lastWinner;
    address public ticketHolder1;
    address public ticketHolder2;
    address public ticketHolder3;
    address public ticketHolder4;
    address public ticketHolder5;
    bool public isLocked;
    uint public randomSeed;

    struct LotteryData {
        bool isLocked;
        uint256 randomSeed;
        uint256 ticketPrice;
        address lastWinner;
        address ticketHolder1;
        address ticketHolder2;
        address ticketHolder3;
        address ticketHolder4;
        address ticketHolder5;
        uint256 currentRound;
        uint256 maxTickets;
        uint256 ticketsSold;
        address owner;
    }

    LotteryData public lotteryData = LotteryData(
        false,
        0,
        0.01 ether,
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        0,
        5,
        0,
        0xB7BB510B0746bdeE208dB6fB781bF5Be39d15A15
    );

    modifier onlyOwner() {
        require(msg.sender == lotteryData.owner);
        _;
    }

    function setLotteryStatus(string newStatus) public onlyOwner {
        status = newStatus;
    }

    function setRandomSeed(uint32 seed) public onlyOwner {
        randomSeed = uint(seed);
        lotteryData.randomSeed = uint(block.blockhash(block.number - randomSeed)) % 2000 + 1;
    }

    function () public payable {
        participateInLottery();
    }

    function participateInLottery() public payable {
        require(!lotteryData.isLocked);
        lotteryData.isLocked = true;

        require(msg.value == lotteryData.ticketPrice);

        if (lotteryData.ticketsSold == 5) {
            lotteryData.ticketsSold -= 1;
            lotteryData.ticketHolder1 = msg.sender;
        } else if (lotteryData.ticketsSold == 4) {
            lotteryData.ticketsSold -= 1;
            lotteryData.ticketHolder2 = msg.sender;
            lotteryData.ticketHolder1.transfer(lotteryData.ticketPrice * 1 / 2);
        } else if (lotteryData.ticketsSold == 3) {
            lotteryData.ticketsSold -= 1;
            lotteryData.ticketHolder3 = msg.sender;
        } else if (lotteryData.ticketsSold == 2) {
            lotteryData.ticketsSold -= 1;
            lotteryData.ticketHolder4 = msg.sender;
        } else if (lotteryData.ticketsSold == 1) {
            lotteryData.ticketHolder5 = msg.sender;
            lotteryData.ticketsSold = 5;
            lotteryData.currentRound += 1;
            randomSeed = uint(block.blockhash(block.number - randomSeed)) % 2000 + 1;
            uint randomNumber = uint(block.blockhash(block.number - randomSeed)) % 5 + 1;

            if (randomNumber == 1) {
                lotteryData.ticketHolder1.transfer(lotteryData.ticketPrice * 9 / 2);
                lotteryData.lastWinner = lotteryData.ticketHolder1;
            } else if (randomNumber == 2) {
                lotteryData.ticketHolder2.transfer(lotteryData.ticketPrice * 9 / 2);
                lotteryData.lastWinner = lotteryData.ticketHolder2;
            } else if (randomNumber == 3) {
                lotteryData.ticketHolder3.transfer(lotteryData.ticketPrice * 9 / 2);
                lotteryData.lastWinner = lotteryData.ticketHolder3;
            } else if (randomNumber == 4) {
                lotteryData.ticketHolder4.transfer(lotteryData.ticketPrice * 9 / 2);
                lotteryData.lastWinner = lotteryData.ticketHolder4;
            } else if (randomNumber == 5) {
                lotteryData.ticketHolder5.transfer(lotteryData.ticketPrice * 9 / 2);
                lotteryData.lastWinner = lotteryData.ticketHolder5;
            }
        }

        lotteryData.isLocked = false;
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getAddressConstant(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getBoolConstant(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [4, 777, 1, 10000000000000000, 5, 2000, 2, 9, 3];
    address payable[] public _address_constant = [0xB7BB510B0746bdeE208dB6fB781bF5Be39d15A15];
    bool[] public _bool_constant = [false, true];
    string[] public _string_constant = ["Running", "Shutdown"];
}
```