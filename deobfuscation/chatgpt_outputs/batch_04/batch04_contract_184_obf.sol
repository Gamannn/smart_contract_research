```solidity
pragma solidity ^0.4.24;

contract LotteryGame {
    uint public houseEdge;
    uint public jackpot;
    uint256 public totalWinsWei;
    uint256 public totalWinsCount;
    address public owner;
    bool public gameAlive;
    uint256 public lastWinWei;
    address public lastWinner;
    uint256 public currentJackpot;
    uint256 public houseBalance;

    struct GameData {
        uint256 betAmount;
        uint256 entryNumber;
        address owner;
        bool gameAlive;
        uint256 totalWinsCount;
        uint256 lastWinWei;
        uint256 lastWinnerAmount;
        address lastWinner;
        uint256 currentJackpot;
        uint256 houseBalance;
    }

    GameData gameData = GameData(
        0x5Bf066c70C2B5, 
        0, 
        address(0), 
        false, 
        0, 
        0, 
        0, 
        address(0), 
        0, 
        0
    );

    function startGame() public {
        gameData.gameAlive = true;
    }

    function stopGame() public onlyOwner {
        gameData.gameAlive = false;
    }

    function play() public payable {
        require(gameData.gameAlive == true);
        require(!isContract(msg.sender));
        require(msg.value == 9 ether);

        gameData.currentJackpot += (msg.value * 98 / 100);
        gameData.houseBalance += (msg.value * 2 / 100);

        if (msg.sender == gameData.lastWinner) {
            gameData.entryNumber++;
            if (gameData.entryNumber % 999 == 0) {
                uint winAmount = gameData.currentJackpot * 80 / 100;
                gameData.currentJackpot -= winAmount;
                gameData.lastWinner = msg.sender;
                gameData.lastWinnerAmount = winAmount;
                gameData.totalWinsCount++;
                gameData.lastWinWei += winAmount;
                msg.sender.transfer(winAmount);
                return;
            }
        } else {
            uint random = uint(keccak256(abi.encodePacked(gameData.entryNumber + block.number, block.number)));
            if (random % 3 == 0) {
                uint winAmount = gameData.currentJackpot * 50 / 100;
                if (address(this).balance - houseEdge > winAmount) {
                    winAmount = (address(this).balance - houseEdge) * 50 / 100;
                }
                gameData.currentJackpot -= winAmount;
                gameData.lastWinner = msg.sender;
                gameData.lastWinnerAmount = winAmount;
                gameData.totalWinsCount++;
                gameData.lastWinWei += winAmount;
                msg.sender.transfer(winAmount);
            }
            return;
        }
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalWinsWei() public view returns (uint256) {
        return gameData.totalWinsCount;
    }

    function getLastWinnerAmount() public view returns (uint256) {
        return gameData.lastWinnerAmount;
    }

    function getLastWinner() public view returns (address) {
        return gameData.lastWinner;
    }

    function getLastWinWei() public view returns (uint256) {
        return gameData.lastWinWei;
    }

    function withdrawHouseEdge(uint amount) public onlyOwner {
        require(amount <= gameData.houseBalance);
        require((address(this).balance - amount) > 0);
        owner.transfer(amount);
        gameData.houseBalance -= amount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint256[] public _integer_constant = [0, 3, 1000000000000000, 98, 999, 9, 50, 100, 1, 80];
    string[] public _string_constant = ["Sender not authorized."];
    bool[] public _bool_constant = [false, true];
    address payable[] public _address_constant = [0x5Bf066c70C2B5e02F1C6723E72e82478Fec41201];
}
```