pragma solidity ^0.4.25;

contract Ox7aa179499ec69f47ff45492ddd9a3e46972dbdd1 {
    address private ownerAddress;
    uint256 public betPrice;
    uint256 private secretNumber;
    
    struct Game {
        address player;
        uint256 chosenNumber;
        bool won;
    }
    
    event GamePlayed(address player, uint256 chosenNumber, bool won);
    
    constructor() public {
        ownerAddress = msg.sender;
        betPrice = 0.03 ether;
    }
    
    function generateSecretNumber() internal {
        secretNumber = uint8(keccak256(blockhash(block.number - 1))) % 2 + 1;
    }
    
    function play(uint256 chosenNumber) public payable {
        require(msg.value == betPrice, 'Please, bet exactly 0.03 ETH');
        require(chosenNumber == 1 || chosenNumber == 2, 'Number must be 1 or 2');
        
        generateSecretNumber();
        
        Game memory currentGame;
        currentGame.player = msg.sender;
        currentGame.chosenNumber = chosenNumber;
        
        evaluateGame(currentGame);
    }
    
    function evaluateGame(Game memory currentGame) internal {
        if (currentGame.chosenNumber == secretNumber) {
            currentGame.won = true;
        } else {
            currentGame.won = false;
        }
        
        emit GamePlayed(currentGame.player, currentGame.chosenNumber, currentGame.won);
        
        if (currentGame.won) {
            selfdestruct(msg.sender);
        } else {
            selfdestruct(ownerAddress);
        }
    }
    
    function emergencyWithdraw() public {
        selfdestruct(msg.sender);
    }
}