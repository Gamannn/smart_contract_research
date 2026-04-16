pragma solidity ^0.4.20;

contract AuctionContract {
    using SafeMath for uint256;

    event Bid(
        uint auctionId,
        address bidder,
        uint bidAmount,
        uint maxBid,
        uint totalBids,
        uint totalPot
    );

    event Winner(
        uint auctionId,
        address winner,
        uint winningBid,
        uint totalPot,
        uint totalDividends
    );

    event EarningsWithdrawal(
        uint auctionId,
        address withdrawer,
        uint amount
    );

    event DividendsWithdrawal(
        uint auctionId,
        address withdrawer,
        uint dividendAmount,
        uint totalPot,
        uint totalDividends,
        uint dividendSharePrice
    );

    uint public constant PAYOUT_FRACTION = 2;
    mapping(address => uint) public earnings;
    uint public totalDividendShares;
    uint public totalPot;
    uint public lastBidTime;
    uint public maxBid;

    function placeBid() public payable {
        require(msg.value > 0);

        uint currentBid = msg.value;
        uint newTotalPot = totalPot.add(currentBid);
        uint newMaxBid = maxBid.add(currentBid);

        if (currentBid > maxBid) {
            maxBid = currentBid;
            lastBidTime = now;
        }

        totalPot = newTotalPot;
        totalDividendShares = totalDividendShares.add(currentBid.div(PAYOUT_FRACTION));

        Bid(now, msg.sender, currentBid, maxBid, totalDividendShares, totalPot);
    }

    function withdrawEarnings() public {
        require(earnings[msg.sender] > 0);
        assert(earnings[msg.sender] <= address(this).balance);

        uint amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);

        EarningsWithdrawal(now, msg.sender, amount);
    }

    function withdrawDividends() public {
        require(totalDividendShares > 0);

        uint dividendAmount = earnings[msg.sender];
        assert(dividendAmount <= address(this).balance);

        earnings[msg.sender] = 0;
        totalDividendShares = totalDividendShares.sub(dividendAmount.div(PAYOUT_FRACTION));

        msg.sender.transfer(dividendAmount);

        DividendsWithdrawal(now, msg.sender, dividendAmount, totalPot, totalDividendShares, dividendAmount.div(totalDividendShares));
    }
}

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
        uint256 c = a / b;
        return c;
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

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [1, 100, 10, 0, 2, 300];