pragma solidity ^0.4.8;

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

contract DecayingToken is Ownable {
    int public currentVelocity;
    uint public lastUpdate;
    uint public decayRate;
    uint public pricePerEther;
    int public totalDisplacement;
    int public largestPro;
    int public largestRetro;

    function DecayingToken(uint initialPrice, uint _decayRate) {
        lastUpdate = now;
        decayRate = _decayRate;
        pricePerEther = initialPrice;
    }

    function timeElapsed() constant returns(uint) {
        return now - lastUpdate;
    }

    function getCurrentVelocity() constant returns(int) {
        if(decayRate == 0) {
            return currentVelocity;
        }
        int direction;
        if(currentVelocity == 0) {
            direction = 0;
        } else if(currentVelocity < 0) {
            direction = -1;
        } else {
            direction = 1;
        }
        uint deltaTime = uint(timeElapsed());
        uint decayAmount = deltaTime * decayRate;
        int newVelocity = currentVelocity + (int(decayAmount) * direction);
        if((currentVelocity > 0 && newVelocity < 0) || (currentVelocity < 0 && newVelocity > 0)) {
            return 0;
        }
        return newVelocity;
    }

    function getCurrentDisplacement() constant returns(int) {
        int deltaTime = int(timeElapsed());
        if(decayRate == 0) {
            return totalDisplacement + (deltaTime * currentVelocity);
        }
        int timeToZero = currentVelocity / int(decayRate);
        if (timeToZero < 0) {
            timeToZero *= -1;
        }
        if(timeElapsed() > uint(timeToZero)) {
            deltaTime = timeToZero;
        }
        int area = ((currentVelocity + getCurrentVelocity()) * deltaTime) / 2;
        return totalDisplacement + area;
    }

    function trade(int direction) payable {
        require(direction == -1 || direction == 1);
        int change = (int(msg.value) * direction * int(pricePerEther)) / 1 ether;
        int newVelocity = getCurrentVelocity() + change;
        int newDisplacement = getCurrentDisplacement();
        currentVelocity = newVelocity;
        totalDisplacement = newDisplacement;
        if(-currentVelocity > largestRetro) {
            largestRetro = -currentVelocity;
        } else if(currentVelocity > largestPro) {
            largestPro = currentVelocity;
        }
        lastUpdate = now;
    }

    function withdrawAll() onlyOwner {
        withdraw(this.balance);
    }

    function withdraw(uint amount) onlyOwner {
        owner.transfer(amount);
    }
}