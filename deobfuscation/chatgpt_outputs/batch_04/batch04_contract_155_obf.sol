pragma solidity ^0.4.18;

contract LotteryEvents {
    event BuyTicket(address indexed buyer);
    event Withdraw(address indexed recipient, uint256 indexed amount, uint256 indexed timestamp);
    event SharedAward(address indexed recipient, uint256 indexed amount, uint256 indexed timestamp);
    event BigAward(address indexed recipient, uint256 indexed amount, uint256 indexed timestamp);
}

contract Lottery is LotteryEvents {
    uint256 constant private TICKET_PRICE = 1000000000000000;
    address private admin = 0x6a7e507ad248f7f04afff68f5727e4e0029eefba;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only for admin");
        _;
    }

    modifier checkBuyValue(uint256 value) {
        require(value == TICKET_PRICE, "please use right buy value");
        _;
    }

    modifier onlyHumans() {
        address sender = msg.sender;
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sender)
        }
        require(codeSize == 0, "sorry humans only");
        _;
    }

    function buyTicket() public payable checkBuyValue(msg.value) onlyHumans {
        emit BuyTicket(msg.sender);
    }

    function withdraw(address recipient, uint256 amount, uint256 timestamp) public onlyAdmin {
        recipient.transfer(amount);
        emit Withdraw(recipient, amount, timestamp);
    }

    function shareAward(address recipient, uint256 amount, uint256 timestamp) public onlyAdmin {
        recipient.transfer(amount);
        emit SharedAward(recipient, amount, timestamp);
    }

    function bigAward(address recipient, uint256 amount, uint256 timestamp) public onlyAdmin {
        recipient.transfer(amount);
        emit BigAward(recipient, amount, timestamp);
    }

    function transferFunds(address recipient, uint256 amount) public onlyAdmin {
        recipient.transfer(amount);
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        string[] storage stringConstants = ["sorry humans only", "only for admin", "please use right buy value"];
        return stringConstants[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        uint256[] storage integerConstants = [0, TICKET_PRICE];
        return integerConstants[index];
    }
}