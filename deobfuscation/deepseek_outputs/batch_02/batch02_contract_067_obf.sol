pragma solidity ^0.4.21;

contract DiceGame {
    function userRollDice(uint, address) payable {}
}

contract Casino {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    address public owner;
    DiceGame public diceGame;
    bool public gameActive;
    
    function Casino() public {
        owner = msg.sender;
        gameActive = false;
    }
    
    function setDiceGameAddress(address _diceGameAddress) public onlyOwner {
        diceGame = DiceGame(_diceGameAddress);
    }
    
    function setGameActive(bool _active) public onlyOwner {
        gameActive = _active;
    }
    
    function () payable {
        if (gameActive == true) {
            require(msg.value == 1 ether);
            diceGame.userRollDice(31, msg.sender);
        } else {
            revert();
        }
    }
}