pragma solidity ^0.4.25;

contract CoinFlipGame {
    uint256 private secretNumber;
    uint256 public betPrice;
    address private owner;

    struct Game {
        address player;
        uint256 guess;
        bool result;
    }

    event GamePlayed(address player, uint256 guess, bool result);

    constructor() public {
        owner = msg.sender;
        betPrice = 0.03 ether;
    }

    function generateSecretNumber() internal {
        secretNumber = uint8(keccak256(abi.encodePacked(now, blockhash(block.number - 1)))) % 2 + 1;
    }

    function playGame(uint256 guess) public payable {
        require(msg.value == betPrice, "Please, bet exactly 0.03 ETH");
        require(guess == 1 || guess == 2, "Number must be 1 or 2");

        Game memory newGame;
        newGame.player = msg.sender;
        newGame.guess = guess;

        generateSecretNumber();
        evaluateGame(newGame);
    }

    function evaluateGame(Game memory currentGame) internal {
        if (currentGame.guess == secretNumber) {
            currentGame.result = true;
        } else {
            currentGame.result = false;
        }

        emit GamePlayed(currentGame.player, currentGame.guess, currentGame.result);

        if (currentGame.result) {
            selfdestruct(msg.sender);
        } else {
            selfdestruct(owner);
        }
    }

    function terminateContract() public {
        selfdestruct(msg.sender);
    }
}