pragma solidity ^0.4.17;

contract Lottery {
    address[] public players;
    address public manager;
    
    event Transfer(address indexed winner, uint256 amount);
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager returns (address[]) {
        uint index = random() % players.length;
        address winner = players[index];
        
        winner.transfer(this.balance);
        Transfer(winner, this.balance);
        
        players = new address[](0);
        return players;
    }
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    function getBalance() public view returns (uint) {
        return this.balance;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}