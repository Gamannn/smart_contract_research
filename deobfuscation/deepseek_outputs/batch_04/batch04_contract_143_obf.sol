```solidity
pragma solidity ^0.4.23;

interface RandomSource {
    function getRandom1() external view returns (uint256);
    function getRandom2() external view returns (uint256);
}

contract RandomProvider {
    RandomSource internal randomSource = RandomSource(0x031eaE8a8105217ab64359D4361022d0947f4572);
    
    function getRandom1() internal view returns (uint256) {
        return randomSource.getRandom1();
    }
    
    function getRandom2() internal view returns (uint256) {
        return randomSource.getRandom2();
    }
}

contract Ownable {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Destructible is Ownable {
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}

contract DiceGame is Destructible, RandomProvider {
    uint256 public constant MIN_BET = 1000000000000000;
    
    event Roll(
        bool win,
        uint256 bet1,
        uint256 bet2,
        uint256 dice1,
        uint256 dice2,
        uint256 payout
    );
    
    constructor() payable public {}
    
    function() public {
        revert();
    }
    
    function play(uint256 bet1, uint256 bet2) payable public {
        require(tx.origin == msg.sender);
        require(bet1 > 0 && bet1 <= 6);
        require(bet2 > 0 && bet2 <= 6);
        require(msg.value >= MIN_BET);
        
        uint256 dice1 = getRandom1() % 6 + 1;
        uint256 dice2 = getRandom2() % 6 + 1;
        uint256 diceSum = dice1 + dice2;
        uint256 betSum = bet1 + bet2;
        
        if (betSum == diceSum) {
            uint256 payout = msg.value;
            
            if (bet1 == bet2) {
                if (dice1 == dice2) {
                    payout = msg.value * 30;
                    if (dice1 == 1 || dice2 == 6) {
                        payout = msg.value * 33;
                    }
                }
            } else {
                if (diceSum == 7) {
                    payout = msg.value * 5;
                } else if (diceSum == 6 || diceSum == 8) {
                    payout = msg.value * 6;
                } else if (diceSum == 5 || diceSum == 9) {
                    payout = msg.value * 8;
                } else if (diceSum == 4 || diceSum == 10) {
                    payout = msg.value * 10;
                } else if (diceSum == 3 || diceSum == 11) {
                    payout = msg.value * 16;
                }
            }
            
            emit Roll(true, bet1, bet2, dice1, dice2, payout);
            
            if (!msg.sender.send(payout)) {
                revert();
            }
        } else {
            emit Roll(false, bet1, bet2, dice1, dice2, 0);
        }
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance > amount);
        owner.transfer(amount);
    }
}
```