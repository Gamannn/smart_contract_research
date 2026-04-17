pragma solidity ^0.4.21;

contract BettingGame {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier gameIsActive() {
        require(isActive);
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin);
        _;
    }

    modifier hasBet() {
        require(bets[msg.sender] > 0);
        _;
    }

    event Wager(uint256 amount, address player);
    event Win(uint256 amount, address player);
    event Lose(uint256 amount, address player);
    event Donate(uint256 amount, address to, address from);
    event DifficultyChanged(uint256 newDifficulty);
    event BetLimitChanged(uint256 newBetLimit);

    address private owner;
    uint256 private betLimit;
    uint256 private difficulty;
    bool private isActive;
    uint256 private totalDonated;
    address private donationAddress;

    mapping(address => uint256) private bets;
    mapping(address => uint256) private timestamps;

    function activateGame() onlyOwner public {
        isActive = true;
    }

    function adjustBetLimit(uint256 newBetLimit) onlyOwner public {
        betLimit = newBetLimit;
        emit BetLimitChanged(betLimit);
    }

    function adjustDifficulty(uint256 newDifficulty) onlyOwner public {
        difficulty = newDifficulty;
        emit DifficultyChanged(difficulty);
    }

    function placeBet() gameIsActive onlyEOA payable public {
        require(msg.value == betLimit);
        timestamps[msg.sender] = block.number;
        bets[msg.sender] = msg.value;
        emit Wager(msg.value, msg.sender);
    }

    function resolveBet() gameIsActive onlyEOA hasBet public {
        uint256 betBlock = timestamps[msg.sender];
        if (betBlock < block.number) {
            timestamps[msg.sender] = 0;
            bets[msg.sender] = 0;
            uint256 winningNumber = uint256(keccak256(abi.encodePacked(blockhash(betBlock), msg.sender))) % difficulty + 1;
            if (winningNumber > difficulty / 2) {
                payout(msg.sender);
            } else {
                loseBet(betLimit / 2);
            }
        } else {
            revert();
        }
    }

    function donate() gameIsActive public payable {
        donateFunds(msg.value);
    }

    function payout(address winner) internal {
        uint256 payoutAmount = address(this).balance / 2;
        winner.transfer(payoutAmount);
        emit Win(payoutAmount, winner);
    }

    function donateFunds(uint256 amount) internal {
        donationAddress.call.value(amount)();
        totalDonated += amount;
        emit Donate(amount, donationAddress, msg.sender);
    }

    function loseBet(uint256 amount) internal {
        donationAddress.call.value(amount)();
        totalDonated += amount;
        emit Donate(amount, donationAddress, msg.sender);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDifficulty() public view returns (uint256) {
        return difficulty;
    }

    function getBetLimit() public view returns (uint256) {
        return betLimit;
    }

    function hasActiveBet(address player) public view returns (bool) {
        return bets[player] > 0;
    }

    function getHalfBalance() public view returns (uint256) {
        return address(this).balance / 2;
    }

    function transferFunds(address to, address from, uint256 amount) public onlyOwner returns (bool) {
        return ExternalContract(to).transferFunds(from, amount);
    }
}

contract ExternalContract {
    function transferFunds(address to, uint256 amount) public returns (bool);
}