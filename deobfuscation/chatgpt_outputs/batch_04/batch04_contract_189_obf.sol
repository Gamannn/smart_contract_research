pragma solidity ^0.4.20;

contract SimpleGame {
    struct GameState {
        address player;
        bool isFinished;
        uint8 number;
    }

    GameState gameState = GameState(address(0), false, 0);

    bool[] public _bool_constant = [false, true];
    uint256[] public _integer_constant = [0, 1000000000000000];

    function playGame(uint8 number) external payable {
        require(msg.sender == tx.origin);
        if (gameState.number == number && msg.value > 0.001 ether && !gameState.isFinished) {
            msg.sender.transfer(this.balance);
            finishGame();
        }
    }

    function startGame(uint8 number) public payable {
        if (gameState.number == 0) {
            gameState.number = number;
            gameState.player = msg.sender;
        }
    }

    function guessNumber(uint8 number) public payable {
        require(msg.sender == gameState.player);
        gameState.number = number;
        if (msg.value > 0.001 ether) {
            msg.sender.transfer(this.balance);
        }
    }

    function finishGame() private {
        gameState.isFinished = true;
    }

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function() public payable {}
}