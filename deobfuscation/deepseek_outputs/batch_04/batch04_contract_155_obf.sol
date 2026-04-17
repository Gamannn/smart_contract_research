pragma solidity ^0.4.18;

contract LotteryEvents {
    event BuyTicket(address indexed buyer);
    event Withdraw(address indexed recipient, uint256 indexed amount, uint256 indexed id);
    event SharedAward(address indexed recipient, uint256 indexed amount, uint256 indexed id);
    event BigAward(address indexed recipient, uint256 indexed amount, uint256 indexed id);
}

contract Lottery is LotteryEvents {
    address public admin;
    uint256 public ticketPrice;
    string[] public errorMessages;
    uint256[] public constants;

    constructor() public {
        admin = msg.sender;
        ticketPrice = 1000000000000000; // 0.001 ETH
        errorMessages.push("sorry humans only");
        errorMessages.push("only for admin");
        errorMessages.push("please use right buy value");
        constants.push(0);
        constants.push(1000000000000000);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, errorMessages[1]);
        _;
    }

    modifier checkTicketPrice(uint256 value) {
        require(value == ticketPrice, errorMessages[2]);
        _;
    }

    modifier noContract() {
        address sender = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0, errorMessages[0]);
        _;
    }

    function buyTicket() public payable checkTicketPrice(msg.value) noContract {
        emit BuyTicket(msg.sender);
    }

    function withdraw(address recipient, uint256 amount, uint256 id) public onlyAdmin {
        recipient.transfer(amount);
        emit Withdraw(recipient, amount, id);
    }

    function awardShared(address recipient, uint256 amount, uint256 id) public onlyAdmin {
        recipient.transfer(amount);
        emit SharedAward(recipient, amount, id);
    }

    function awardBig(address recipient, uint256 amount, uint256 id) public onlyAdmin {
        recipient.transfer(amount);
        emit BigAward(recipient, amount, id);
    }

    function adminTransfer(address recipient, uint256 amount) public onlyAdmin {
        recipient.transfer(amount);
    }
}