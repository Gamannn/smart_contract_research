pragma solidity ^0.4.0;

contract PayoutContract {
    event Payout(address indexed beneficiary);
    event ParticipantJoined(address indexed participant);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint public queueSize;
    uint public payoutAmount;
    uint public buyInAmount;
    uint public roundsUntilPayout;
    address owner;
    mapping (uint => address) queue;
    mapping (address => uint) balances;

    function PayoutContract() public {
        owner = msg.sender;
    }

    function() public payable {
        participate();
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function addToQueue() internal {
        queue[queueSize] = msg.sender;
        queueSize++;
    }

    function processQueue() internal {
        address beneficiary = queue[queueSize - roundsUntilPayout];
        balances[beneficiary] += payoutAmount;
        queueSize++;
        emit Payout(beneficiary);
    }

    function isRoundComplete() internal view returns (bool) {
        return queueSize % roundsUntilPayout == 0;
    }

    function participate() internal {
        bool insufficientFunds = msg.value < buyInAmount;
        if (insufficientFunds) {
            return;
        }
        addToQueue();
        emit ParticipantJoined(msg.sender);
        if (isRoundComplete()) {
            processQueue();
        }
    }

    function setBuyInAmount(uint newBuyInAmount) public onlyOwner {
        buyInAmount = newBuyInAmount;
    }

    function setRoundsUntilPayout(uint newRoundsUntilPayout) public onlyOwner {
        roundsUntilPayout = newRoundsUntilPayout;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setPayoutAmount(uint newPayoutAmount) public onlyOwner {
        payoutAmount = newPayoutAmount;
    }

    function transferFunds(uint amount) public onlyOwner {
        owner.transfer(amount);
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [10000000000000000, 0, 1, 20000000000000000, 3];
}