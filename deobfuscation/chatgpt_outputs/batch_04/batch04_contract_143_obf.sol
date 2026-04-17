```solidity
pragma solidity ^0.4.23;

contract RandomNumberGenerator {
    function getRandomNumber1() external view returns (uint256);
    function getRandomNumber2() external view returns (uint256);
}

contract RandomNumberProvider {
    RandomNumberGenerator internal randomNumberGenerator = RandomNumberGenerator(0x031eaE8a8105217ab64359D4361022d0947f4572);

    function getRandomNumber1() internal view returns (uint256) {
        return randomNumberGenerator.getRandomNumber1();
    }

    function getRandomNumber2() internal view returns (uint256) {
        return randomNumberGenerator.getRandomNumber2();
    }
}

contract Owner {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract SelfDestructible is Owner {
    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }
}

contract DiceGame is SelfDestructible, RandomNumberProvider {
    uint256 public constant MIN_BET = 1000000000000000;

    event Roll(bool win, uint playerRoll1, uint playerRoll2, uint randomRoll1, uint randomRoll2, uint payout);

    constructor() payable public {}

    function() public {
        revert();
    }

    function placeBet(uint playerRoll1, uint playerRoll2) payable public {
        require(tx.origin == msg.sender);
        require(playerRoll1 > 0 && playerRoll1 <= 6);
        require(playerRoll2 > 0 && playerRoll2 <= 6);
        require(msg.value >= MIN_BET);

        uint256 randomRoll1 = getRandomNumber1() % 6 + 1;
        uint256 randomRoll2 = getRandomNumber2() % 6 + 1;
        uint256 randomSum = randomRoll1 + randomRoll2;
        uint256 playerSum = playerRoll1 + playerRoll2;

        if (playerSum == randomSum) {
            uint payout = msg.value;
            if (playerRoll1 == playerRoll2) {
                if (randomRoll1 == randomRoll2) {
                    payout = msg.value * 30;
                    if (randomRoll1 == 1 || randomRoll2 == 6) {
                        payout = msg.value * 33;
                    }
                    emit Roll(true, playerRoll1, playerRoll2, randomRoll1, randomRoll2, payout);
                } else {
                    emit Roll(false, playerRoll1, playerRoll2, randomRoll1, randomRoll2, 0);
                }
            } else {
                if (randomSum == 7) payout = msg.value * 5;
                if (randomSum == 6 || randomSum == 8) payout = msg.value * 6;
                if (randomSum == 5 || randomSum == 9) payout = msg.value * 8;
                if (randomSum == 4 || randomSum == 10) payout = msg.value * 10;
                if (randomSum == 3 || randomSum == 11) payout = msg.value * 16;
                emit Roll(true, playerRoll1, playerRoll2, randomRoll1, randomRoll2, payout);
            }
            if (!msg.sender.send(payout)) revert();
        } else {
            emit Roll(false, playerRoll1, playerRoll2, randomRoll1, randomRoll2, 0);
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance > amount);
        owner.transfer(amount);
    }
}
```