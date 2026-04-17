pragma solidity 0.5.4;

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner() {
        require(msg.sender == newOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Lottery is Ownable {
    using SafeMath for uint;

    mapping(uint => address) public roundWinners;
    mapping(uint => uint) public roundJackpots;

    uint public ticketPrice = 0.001 ether;
    uint public startTime = 1551700800;
    uint public roundDuration = 3600; // in seconds

    address payable public wallet;
    address payable public superJackpotWallet;

    constructor(address payable _wallet, address payable _superJackpotWallet) public {
        require(_wallet != address(0));
        require(_superJackpotWallet != address(0));

        wallet = _wallet;
        superJackpotWallet = _superJackpotWallet;
    }

    function() external payable {
        buyTicket(msg.sender);
    }

    function buyTicket(address participant) public payable {
        require(msg.value >= ticketPrice);

        uint currentRound = now.sub(startTime).div(roundDuration);
        uint amount = msg.value;

        uint walletShare = amount.mul(20).div(100);
        uint superJackpotShare = amount.mul(15).div(100);
        uint jackpotShare = amount.mul(15).div(100);

        roundWinners[currentRound] = participant;
        roundJackpots[currentRound] = roundJackpots[currentRound].add(amount).sub(walletShare).sub(superJackpotShare).sub(jackpotShare);
        roundJackpots[currentRound.add(1)] = roundJackpots[currentRound.add(1)].add(superJackpotShare);

        superJackpotWallet.transfer(superJackpotShare);
        wallet.transfer(walletShare);
    }

    function getRoundWinner(uint round) public view returns (address) {
        if (roundWinners[round] != address(0)) {
            return roundWinners[round];
        } else {
            return owner;
        }
    }

    function claimJackpot(uint round) public {
        require(round < now.sub(startTime).div(roundDuration));
        require(msg.sender == getRoundWinner(round));

        uint jackpot = roundJackpots[round];
        roundJackpots[round] = 0;

        address(msg.sender).transfer(jackpot);
    }

    function setRoundDuration(uint _roundDuration) public onlyOwner {
        roundDuration = _roundDuration;
    }

    function setStartTime(uint _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setSuperJackpotWallet(address payable _superJackpotWallet) public onlyOwner {
        superJackpotWallet = _superJackpotWallet;
    }

    function getCurrentRound() public view returns (uint) {
        return now.sub(startTime).div(roundDuration);
    }

    function getRoundJackpot(uint round) public view returns (uint) {
        return roundJackpots[round];
    }

    function calculateRound(uint timestamp) public view returns (uint) {
        return timestamp.sub(startTime).div(roundDuration);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}