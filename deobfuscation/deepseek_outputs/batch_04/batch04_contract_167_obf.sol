pragma solidity ^0.4.21;

contract Lottery {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier isOpen() {
        require(isOpenToPublic);
        _;
    }
    
    modifier onlyHuman() {
        require(msg.sender == tx.origin);
        _;
    }
    
    modifier hasActiveBet() {
        require(playerBets[msg.sender] > 0);
        _;
    }
    
    event Wager(uint256 amount, address player);
    event Win(uint256 amount, address winner);
    event Lose(uint256 amount, address loser);
    event Donate(uint256 amount, address whale, address donor);
    event DifficultyChanged(uint256 difficulty);
    event BetLimitChanged(uint256 betLimit);
    
    address private whale;
    uint256 public betLimit;
    uint256 public difficulty;
    bool public isOpenToPublic;
    uint256 public totalDonated;
    address public owner;
    
    mapping(address => uint256) public playerBets;
    mapping(address => uint256) public betTimestamps;
    
    constructor() public {
        owner = msg.sender;
        isOpenToPublic = false;
        totalDonated = 0;
        whale = address(0);
        betLimit = 0;
        difficulty = 0;
    }
    
    function openToPublic() onlyOwner() public {
        isOpenToPublic = true;
    }
    
    function adjustBetLimit(uint256 newLimit) onlyOwner() public {
        betLimit = newLimit;
        emit BetLimitChanged(betLimit);
    }
    
    function adjustDifficulty(uint256 newDifficulty) onlyOwner() public {
        difficulty = newDifficulty;
        emit DifficultyChanged(difficulty);
    }
    
    function() public payable {
        donate();
    }
    
    function placeBet() isOpen() onlyHuman() payable public {
        require(msg.value == betLimit);
        betTimestamps[msg.sender] = block.number;
        playerBets[msg.sender] = msg.value;
        emit Wager(msg.value, msg.sender);
    }
    
    function resolveBet() isOpen() onlyHuman() hasActiveBet() public {
        uint256 betBlock = betTimestamps[msg.sender];
        
        if(betBlock < block.number) {
            betTimestamps[msg.sender] = 0;
            playerBets[msg.sender] = 0;
            
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(betBlock), msg.sender))) % difficulty + 1;
            
            if(randomNumber < difficulty / 2) {
                payout(msg.sender);
            } else {
                loseBet(betLimit / 2);
            }
        } else {
            revert();
        }
    }
    
    function donate() isOpen() public payable {
        donateToWhale(msg.value);
    }
    
    function payout(address winner) internal {
        uint256 winAmount = address(this).balance / 2;
        winner.transfer(winAmount);
        emit Win(winAmount, winner);
    }
    
    function donateToWhale(uint256 amount) internal {
        whale.call.value(amount)(bytes4(keccak256("donate()")));
        totalDonated += amount;
        emit Donate(amount, whale, msg.sender);
    }
    
    function loseBet(uint256 amount) internal {
        whale.call.value(amount)(bytes4(keccak256("donate()")));
        totalDonated += amount;
        emit Lose(amount, msg.sender);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getDifficulty() public view returns (uint256) {
        return difficulty;
    }
    
    function getBetLimit() public view returns (uint256) {
        return betLimit;
    }
    
    function hasBet(address player) public view returns (bool) {
        if(playerBets[player] > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function getWinAmount() public view returns (uint256) {
        return address(this).balance / 2;
    }
    
    function transferToken(address token, address to, uint256 amount) public onlyOwner() returns (bool success) {
        return ERC20(token).transfer(to, amount);
    }
}

contract ERC20 {
    function transfer(address to, uint256 amount) public returns (bool success);
}