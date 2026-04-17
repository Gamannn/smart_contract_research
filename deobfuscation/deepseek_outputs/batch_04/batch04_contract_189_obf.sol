```solidity
pragma solidity ^0.4.20;

contract Ox20f93acf04f032fcaf80e06f74b9c82997c693e2 {
    struct GameData {
        address lastPlayer;
        bool finished;
        uint8 secretNumber;
    }
    
    GameData private gameData = GameData(address(0), false, 0);
    
    function guessNumber(uint8 guess) external payable {
        require(msg.sender == tx.origin);
        
        if (gameData.secretNumber == guess && 
            msg.value > 0.001 ether && 
            !gameData.finished) {
            msg.sender.transfer(this.balance);
            finishGame();
        }
    }
    
    function setSecretNumber(uint8 secret) public payable {
        if (gameData.secretNumber == 0) {
            gameData.secretNumber = secret;
            gameData.lastPlayer = msg.sender;
        }
    }
    
    function revealSecret(uint8 secret) public payable {
        require(msg.sender == gameData.lastPlayer);
        gameData.lastPlayer = address(0);
        gameData.secretNumber = secret;
        
        if (msg.value > 0.001 ether) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function finishGame() private {
        gameData.finished = true;
    }
    
    function() public payable {}
    
    bool[] public _bool_constant = [false, true];
    uint256[] public _integer_constant = [0, 1000000000000000];
    
    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}
```