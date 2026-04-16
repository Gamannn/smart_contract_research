```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    modifier onlyHuman() {
        address addr = msg.sender;
        uint256 size;
        assembly { size := extcodesize(addr) }
        require(size == 0, "sorry humans only");
        _;
    }
}

contract Events {
    event BuyEvent(
        address indexed player,
        uint playerId,
        uint amount
    );
    
    event RewardEvent(
        address indexed player,
        uint playerId,
        uint reward
    );
}

contract BubbleGame is Ownable, Events {
    using SafeMath for uint;
    
    address private wallet1;
    address private wallet2;
    
    uint public startAtBlockNumber;
    uint public totalPlayers = 1000;
    bool public gamePaused = false;
    uint public gameRound = 0;
    
    mapping(address => uint) public playerRefxAddr;
    mapping(uint => address) public playerRefxAddrInv;
    mapping(uint => uint) public playerRefCode;
    mapping(uint => uint) public fBubblesL1;
    mapping(uint => uint) public fBubblesL2;
    mapping(uint => uint) public fBubblesL3;
    mapping(address => uint) public playerEarnings;
    mapping(uint => uint) public playerRefCount;
    
    uint public curBubbleNumber = 1;
    mapping(uint => address) public bubbleOwner;
    mapping(uint => uint) public bubblePlayerId;
    
    constructor(address _wallet1, address _wallet2) public {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        startAtBlockNumber = block.number + 633;
    }
    
    function buy(uint refCode) public onlyHuman payable returns(uint) {
        require(block.number >= startAtBlockNumber, "Not Start");
        require(playerRefxAddrInv[refCode] != address(0) || (refCode == 0 && gameRound == 0));
        require(msg.value >= 0.1 ether, "Minima amoun:0.1 ether");
        
        bool isNewPlayer = false;
        uint playerId;
        
        if(playerRefxAddr[msg.sender] == 0) {
            playerId = totalPlayers + 1;
            playerRefxAddr[msg.sender] = playerId;
            playerRefCode[playerId] = refCode;
            fBubblesL1[playerId] = 6;
            fBubblesL2[playerId] = 36;
            fBubblesL3[playerId] = 216;
            isNewPlayer = true;
        } else {
            playerId = playerRefxAddr[msg.sender];
            refCode = playerRefCode[playerId];
            fBubblesL1[playerRefxAddr[msg.sender]] += 6;
            fBubblesL2[playerRefxAddr[msg.sender]] += 36;
            fBubblesL3[playerRefxAddr[msg.sender]] += 216;
        }
        
        uint up1Ref = refCode;
        uint up2Ref = 0;
        uint up3Ref = 0;
        
        if(gameRound > 0 && fBubblesL2[up1Ref] > 0) {
            fBubblesL2[up1Ref] -= 1;
            up2Ref = playerRefCode[up1Ref];
            if(isNewPlayer) {
                playerRefCount[up1Ref] += 1;
            }
        }
        
        if(playerRefCode[up2Ref] != 0 && fBubblesL3[refCode] > 0) {
            fBubblesL3[refCode] -= 1;
            up3Ref = playerRefCode[up2Ref];
            if(isNewPlayer) {
                playerRefCount[up2Ref] += 1;
            }
        }
        
        playerRefxAddrInv[playerRefxAddr[msg.sender]] = msg.sender;
        bubbleOwner[curBubbleNumber] = msg.sender;
        bubblePlayerId[curBubbleNumber] = playerId;
        totalPlayers = playerId;
        
        if(isNewPlayer) {
            gameRound += 1;
        }
        
        emit BuyEvent(msg.sender, playerId, msg.value);
        
        distributeRewards(msg.value, up1Ref, up2Ref, up3Ref);
    }
    
    function distributeRewards(uint amount, uint up1Ref, uint up2Ref, uint up3Ref) internal {
        uint reward1;
        uint reward2;
        uint reward3;
        uint reward4;
        
        reward1 = amount.mul(40 ether).div(100 ether);
        reward2 = amount.mul(30 ether).div(100 ether);
        reward3 = amount.mul(20 ether).div(100 ether);
        reward4 = amount.mul(7 ether).div(100 ether);
        uint reward5 = amount.mul(3 ether).div(100 ether);
        
        if(up1Ref != 0) {
            playerRefxAddrInv[up1Ref].transfer(reward1);
            playerEarnings[playerRefxAddrInv[up1Ref]] = playerEarnings[playerRefxAddrInv[up1Ref]].add(reward1);
            emit RewardEvent(playerRefxAddrInv[up1Ref], up1Ref, reward1);
        }
        
        if(up2Ref != 0) {
            playerRefxAddrInv[up2Ref].transfer(reward2);
            playerEarnings[playerRefxAddrInv[up2Ref]] = playerEarnings[playerRefxAddrInv[up2Ref]].add(reward2);
            emit RewardEvent(playerRefxAddrInv[up2Ref], up2Ref, reward2);
        }
        
        if(up3Ref != 0) {
            playerRefxAddrInv[up3Ref].transfer(reward3);
            playerEarnings[playerRefxAddrInv[up3Ref]] = playerEarnings[playerRefxAddrInv[up3Ref]].add(reward3);
            emit RewardEvent(playerRefxAddrInv[up3Ref], up3Ref, reward3);
        }
        
        wallet1.transfer(reward4);
        wallet2.transfer(reward5);
    }
    
    function withdraw(uint amount) public onlyOwner {
        owner.transfer(amount);
    }
    
    function getPlayerInfo() public view returns(uint, uint, uint, uint) {
        uint refCode = playerRefxAddr[msg.sender];
        return (
            playerEarnings[msg.sender],
            playerRefCount[refCode],
            refCode,
            gameRound
        );
    }
    
    function getBubbleInfo() public view returns(uint, uint, uint) {
        return (
            fBubblesL1[playerRefxAddr[msg.sender]],
            fBubblesL2[playerRefxAddr[msg.sender]],
            fBubblesL3[playerRefxAddr[msg.sender]]
        );
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
```