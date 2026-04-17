```solidity
pragma solidity ^0.4.20;

contract EtherGame {
    address[][] public playerRounds;
    mapping(address => uint) public balances;
    bool gameActive;
    address owner;

    struct GameState {
        bool isGameActive;
        address owner;
    }

    GameState gameState = GameState(false, 0x5372260584003e8Ae3a24E9dF09fa96037a04c2b);

    function getNumberOfRounds() public view returns (uint) {
        return playerRounds.length;
    }

    function getNumberOfPlayersInRound(uint roundIndex) public view returns (uint) {
        return playerRounds[roundIndex].length;
    }

    function calculateEntryFee(uint roundIndex) public pure returns (uint) {
        return 0.005 ether * (uint(2) ** roundIndex);
    }

    function setGameActive(bool isActive) public {
        require(msg.sender == gameState.owner);
        gameState.isGameActive = isActive;
    }

    function joinRound(uint roundIndex, uint playerIndex) public payable {
        balances[msg.sender] += msg.value;
        require(balances[msg.sender] >= calculateEntryFee(playerIndex));

        balances[msg.sender] -= calculateEntryFee(playerIndex);

        if (roundIndex == playerRounds.length) {
            require(gameState.isGameActive == false);
            playerRounds.length++;
        } else if (roundIndex > playerRounds.length) {
            revert();
        }

        require(playerIndex == playerRounds[roundIndex].length);
        playerRounds[roundIndex].push(msg.sender);

        if (playerIndex == 0) {
            balances[gameState.owner] += calculateEntryFee(playerIndex);
        } else {
            balances[playerRounds[roundIndex][playerIndex - 1]] += calculateEntryFee(playerIndex) * 99 / 100;
            balances[gameState.owner] += calculateEntryFee(playerIndex) * 1 / 100;
        }
    }

    function withdraw() public {
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function getAddressConstant(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getBoolConstant(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    address payable[] public _address_constant = [0x5372260584003e8Ae3a24E9dF09fa96037a04c2b];
    uint256[] public _integer_constant = [1, 0, 99, 5000000000000000, 100, 2];
    bool[] public _bool_constant = [false];
}
```