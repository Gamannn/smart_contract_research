pragma solidity >=0.5.0 <0.6.0;

contract Ox059c8a2c78281735fce0b64bf2a4cf0625ca5461 {
    event Win(address indexed player, uint amount);
    event Lose(address indexed player, uint amount);
    
    struct GameState {
        uint betBlockNumber;
        uint totalWon;
        uint totalBet;
        uint currentBet;
        address currentPlayer;
        address houseAddress;
        address owner;
    }
    
    GameState private state;
    
    constructor(address payable houseAddress) public payable {
        state.owner = msg.sender;
        state.houseAddress = houseAddress;
        state.totalBet = 0;
        state.totalWon = 0;
        state.currentPlayer = address(0);
    }
    
    function setHouseAddress(address payable newHouseAddress) public {
        require(msg.sender == state.owner, 'Only owner can set new house address!');
        state.houseAddress = newHouseAddress;
    }
    
    function () external payable {
        require(msg.value <= (address(this).balance / 5 - 1), 'The stake is too high, check maxBet() before placing a bet.');
        require(msg.value == 0 || state.currentPlayer == address(0), 'Either bet with a value or collect without.');
        
        if (state.currentPlayer == address(0)) {
            require(msg.value > 0, 'You must set a bet by sending some value > 0');
            state.currentPlayer = msg.sender;
            state.currentBet = msg.value;
            state.betBlockNumber = block.number;
            state.totalBet += state.currentBet;
        } else {
            require(msg.sender == state.currentPlayer, 'Only the current player can collect the prize');
            require(block.number > (state.betBlockNumber + 1), 'Please wait until another block has been mined');
            
            if (((uint(blockhash(state.betBlockNumber + 1)) % 50 > 0) && 
                 (uint(blockhash(state.betBlockNumber + 1)) % 2 == uint(blockhash(state.betBlockNumber)) % 2)) || 
                (msg.sender == state.houseAddress)) {
                
                emit Win(msg.sender, state.currentBet);
                uint prize = state.currentBet * 2;
                state.totalWon += state.currentBet;
                state.currentBet = 0;
                msg.sender.transfer(prize);
            } else {
                emit Lose(msg.sender, state.currentBet);
                state.currentBet = 0;
            }
            
            state.currentPlayer = address(0);
            state.currentBet = 0;
            state.betBlockNumber = 0;
        }
    }
    
    function maxBet() public view returns (uint) {
        return address(this).balance / 5 - 1;
    }
    
    function randomResult() public view returns (uint) {
        return uint(blockhash(state.betBlockNumber)) % 100;
    }
    
    function currentPlayer() public view returns (address) {
        return state.currentPlayer;
    }
    
    function currentBet() public view returns (uint) {
        return state.currentBet;
    }
    
    function betBlockNumber() public view returns (uint) {
        return state.betBlockNumber;
    }
}