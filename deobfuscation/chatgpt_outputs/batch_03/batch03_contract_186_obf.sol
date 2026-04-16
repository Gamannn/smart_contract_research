pragma solidity ^0.4.24;

contract Lottery {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notPooh(address aContract) {
        require(aContract != address(poohContract));
        _;
    }

    modifier isOpenToPublic() {
        require(openToPublic);
        _;
    }

    event Deposit(uint256 amount, address depositer);
    event WinnerPaid(uint256 amount, address winner);

    POOH poohContract;
    address owner;
    bool openToPublic = false;
    uint256 ticketNumber = 0;
    uint256 winningNumber;

    constructor() public {
        owner = msg.sender;
    }

    function() payable public {}

    function deposit() isOpenToPublic() payable public {
        require(msg.value >= 0.01 ether);
        address customerAddress = msg.sender;
        poohContract.buy.value(msg.value)(customerAddress);
        emit Deposit(msg.value, msg.sender);

        if (msg.value > 0.01 ether) {
            uint extraTickets = SafeMath.div(msg.value, 0.01 ether);
            ticketNumber += extraTickets;
        }

        if (ticketNumber == winningNumber) {
            payDev(owner);
            payWinner(customerAddress);
        } else {
            ticketNumber++;
        }
    }

    function myTokens() public view returns (uint256) {
        return poohContract.myTokens();
    }

    function myDividends() public view returns (uint256) {
        return poohContract.myDividends(true);
    }

    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function openToThePublic() onlyOwner() public {
        openToPublic = true;
        resetLottery();
    }

    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner() notPooh(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }

    function payWinner(address winner) internal {
        uint balance = SafeMath.sub(address(this).balance, 0.05 ether);
        winner.transfer(balance);
        emit WinnerPaid(balance, winner);
    }

    function payDev(address dev) internal {
        uint balance = SafeMath.div(address(this).balance, 10);
        dev.transfer(balance);
    }

    function resetLottery() internal isOpenToPublic() {
        ticketNumber = 1;
        winningNumber = uint256(keccak256(block.timestamp, block.difficulty)) % 300;
    }
}

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract POOH {
    function buy(address) public payable returns (uint256);
    function exit() public;
    function myTokens() public view returns (uint256);
    function myDividends(bool) public view returns (uint256);
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}