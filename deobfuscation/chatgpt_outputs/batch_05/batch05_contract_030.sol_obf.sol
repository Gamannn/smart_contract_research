pragma solidity ^0.4.19;

contract Lottery {
    struct LotteryState {
        address owner;
        uint256 totalBounty;
        uint256 numTickets;
        uint8 direction;
        uint256 lastTicketTime;
        uint256 lottoIndex;
        uint256 ticketPrice;
        uint256 maxTickets;
    }

    LotteryState state = LotteryState(address(0), 0, 0, 0, 0, 0, 0, 0);

    event NewTicket(address indexed player, bool isComplete);
    event LottoComplete(address indexed winner, uint indexed lottoIndex, uint256 totalBounty);

    function Lottery() public {
        state.owner = msg.sender;
        state.ticketPrice = 0.0101 * 10**18;
        state.maxTickets = getIntFunc(3);
        state.direction = uint8(getIntFunc(0));
        state.lottoIndex = 1;
        state.numTickets = 0;
        state.totalBounty = 0;
        state.lastTicketTime = 0;
    }

    function balance() public view returns (uint256) {
        uint256 balance = 0;
        if (state.owner == msg.sender) {
            balance = this.balance;
        }
        return balance;
    }

    function draw() public {
        require(state.owner == msg.sender);
        state.lottoIndex += 1;
        state.numTickets = 0;
        state.totalBounty = 0;
        state.lastTicketTime = 0;
        state.owner.transfer(this.balance);
    }

    function buyTicket() public payable {
        require(msg.value == state.ticketPrice);
        require(state.numTickets < state.maxTickets);

        state.lastTicketTime = now;
        state.numTickets += 1;
        state.totalBounty += state.ticketPrice;

        bool isComplete = state.numTickets == state.maxTickets;
        NewTicket(msg.sender, isComplete);

        if (isComplete) {
            payWinner(msg.sender);
        }
    }

    function payWinner(address winner) private {
        require(state.numTickets == state.maxTickets);

        uint ownerTax = state.totalBounty * 6 / 100;
        uint winnerPrize = state.totalBounty - ownerTax;

        LottoComplete(winner, state.lottoIndex, winnerPrize);

        state.owner.transfer(ownerTax);
        winner.transfer(winnerPrize);

        resetLottery();
    }

    function resetLottery() private {
        state.numTickets = 0;
        state.totalBounty = 0;
        state.lastTicketTime = 0;

        if (state.direction == 0 && state.maxTickets == 20) {
            state.direction = 1;
        } else if (state.direction == 1 && state.maxTickets == 10) {
            state.direction = 0;
        }

        if (state.direction == 0 && state.maxTickets < 20) {
            state.maxTickets += 1;
        } else if (state.direction == 1 && state.maxTickets > 10) {
            state.maxTickets -= 1;
        }
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [10, 1, 6, 18, 20, 100, 0];
}