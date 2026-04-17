pragma solidity ^0.4.21;

contract Lottery {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => uint) private playerBalances;
    mapping(address => uint) public playerBets;
    mapping(address => uint) public playerGames;
    mapping(address => uint) public playerWins;
    mapping(address => uint) private playerLastGame;
    mapping(address => uint) private playerLastWin;
    mapping(uint => address) private winningNumbers;

    uint public currentGame;
    address public contractAddress;
    address public owner;
    address public lastWinner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyNewGame() {
        require(playerBets[msg.sender] == 0);
        _;
    }

    function setCurrentGame(uint gameNumber) public onlyNewGame onlyOwner {
        currentGame = gameNumber;
    }

    function startNewGame() public {
        contractAddress = this;
        playerGames[contractAddress]++;
        playerBets[contractAddress] = 100;
        owner = msg.sender;
        currentGame = 0.005 ether;
    }

    function getLastWinner() public view returns (uint, uint, address) {
        uint status = 0;
        uint lastGame = playerBets[contractAddress];
        address lastWinnerAddress = lastWinner;
        if (playerLastGame[msg.sender] == playerGames[contractAddress]) {
            status = 1;
        }
        return (status, lastGame, lastWinnerAddress);
    }

    modifier validBet(uint betAmount) {
        require(playerLastGame[msg.sender] < playerGames[contractAddress]);
        require(playerBets[contractAddress] > 0);
        require(msg.value == currentGame);
        require(betAmount > 0 && betAmount != 0);
        _;
    }

    function placeBet(uint betAmount) payable validBet(betAmount) {
        playerLastWin[msg.sender] = 0;
        playerBets[contractAddress]++;
        playerLastGame[msg.sender] = playerGames[contractAddress];
        uint randomNumber = uint(keccak256(betAmount + now));
        playerBalances[contractAddress] += randomNumber;
        playerLastWin[msg.sender] = playerBets[contractAddress];
        winningNumbers[playerLastWin[msg.sender]] = msg.sender;

        if (playerBets[contractAddress] == playerWins[contractAddress]) {
            playerGames[contractAddress]++;
            uint winningNumber = uint(keccak256(now + playerGames[contractAddress])) % 100 + 1;
            address winner = winningNumbers[winningNumber];
            winner.transfer(currentGame * 99);
            owner.transfer(currentGame * 1);
            lastWinner = winner;
            playerBets[contractAddress] = 0;
        }
    }

    function getIntFunc(uint256 index) public view returns (uint256) {
        return _integer_constant[index];
    }

    struct Scalar2Vector {
        address contractAddress;
        address owner;
        address lastWinner;
        uint256 currentGame;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0), address(0), address(0), 0.005 ether);

    uint256[] public _integer_constant = [99, 100, 1, 5000000000000000, 0];
}