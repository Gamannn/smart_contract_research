pragma solidity >=0.5.0 <0.6.0;

contract BettingGame {
    event Win(address winner, uint amount);
    event Lose(address loser, uint amount);

    struct GameState {
        uint256 lastBlockNumber;
        uint256 totalWins;
        uint256 totalBets;
        uint256 currentBetAmount;
        address currentPlayer;
        address owner;
        address house;
    }

    GameState gameState;

    constructor(address payable houseAddress) public payable {
        gameState.owner = msg.sender;
        gameState.house = houseAddress;
        gameState.totalBets = 0;
        gameState.totalWins = 0;
        gameState.currentPlayer = address(0);
    }

    function setHouseAddress(address payable newHouseAddress) public payable {
        require(msg.sender == gameState.owner, 'Only the owner can set the new house address!');
        gameState.house = newHouseAddress;
    }

    function() external payable {
        require(msg.value <= (address(this).balance / 5 - 1), 'The stake is too high, check maxBet() before placing a bet.');
        require(msg.value == 0 || gameState.currentPlayer == address(0), 'Either bet with a value or collect without.');

        if (gameState.currentPlayer == address(0)) {
            require(msg.value > 0, 'You must set a bet by sending some value > 0');
            gameState.currentPlayer = msg.sender;
            gameState.currentBetAmount = msg.value;
            gameState.lastBlockNumber = block.number;
            gameState.totalBets += gameState.currentBetAmount;
        } else {
            require(msg.sender == gameState.currentPlayer, 'Only the current player can collect the prize');
            require(block.number > (gameState.lastBlockNumber + 1), 'Please wait until another block has been mined');

            if (((uint(blockhash(gameState.lastBlockNumber + 1)) % 50 > 0) && 
                (uint(blockhash(gameState.lastBlockNumber + 1)) % 2 == uint(blockhash(gameState.lastBlockNumber)) % 2)) || 
                (msg.sender == gameState.house)) {
                
                emit Win(msg.sender, gameState.currentBetAmount);
                uint prize = gameState.currentBetAmount * 2;
                gameState.totalWins += gameState.currentBetAmount;
                gameState.currentBetAmount = 0;
                msg.sender.transfer(prize);
            } else {
                emit Lose(msg.sender, gameState.currentBetAmount);
                gameState.currentBetAmount = 0;
            }

            gameState.currentPlayer = address(0);
            gameState.currentBetAmount = 0;
            gameState.lastBlockNumber = 0;
        }
    }

    function maxBet() public view returns (uint) {
        return address(this).balance / 5 - 1;
    }

    function getLastBlockHash() public view returns (uint) {
        return uint(blockhash(gameState.lastBlockNumber)) % 100;
    }

    function getCurrentPlayer() public view returns (address) {
        return gameState.currentPlayer;
    }

    function getCurrentBetAmount() public view returns (uint) {
        return gameState.currentBetAmount;
    }

    function getLastBlockNumber() public view returns (uint) {
        return gameState.lastBlockNumber;
    }
}