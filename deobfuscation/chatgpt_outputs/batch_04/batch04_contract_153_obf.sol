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

contract DecayContract is Ownable {
    int public currentDisplacement;
    int public largestDisplacement;
    uint public lastUpdate;
    uint public decayRatePerEther;

    function DecayContract(uint initialDisplacement, uint decayRate) {
        lastUpdate = now;
        decayRatePerEther = decayRate;
        currentDisplacement = int(initialDisplacement);
    }

    function getTimeElapsed() constant returns(uint) {
        return now - lastUpdate;
    }

    function getCurrentDisplacement() constant returns(int) {
        if (decayRatePerEther == 0) {
            return currentDisplacement;
        }

        int decayFactor = decayRatePerEther;
        if (currentDisplacement == 0) {
            return 0;
        } else if (currentDisplacement < 0) {
            decayFactor = -1;
        }

        uint timeElapsed = getTimeElapsed();
        uint decayAmount = timeElapsed * decayRatePerEther;
        int newDisplacement = currentDisplacement + (int(decayAmount) * decayFactor);

        if ((currentDisplacement > 0 && newDisplacement < 0) || (currentDisplacement < 0 && newDisplacement > 0)) {
            return 0;
        }

        return newDisplacement;
    }

    function getProjectedDisplacement() constant returns(int) {
        int timeElapsed = int(getTimeElapsed());

        if (decayRatePerEther == 0) {
            return largestDisplacement + (timeElapsed * currentDisplacement);
        }

        int decayFactor = currentDisplacement / int(decayRatePerEther);
        if (decayFactor < 0) {
            decayFactor *= -1;
        }

        int projectedDisplacement = ((currentDisplacement + getCurrentDisplacement()) * timeElapsed) / 2;
        return largestDisplacement + projectedDisplacement;
    }

    function updateDisplacement(int direction) payable {
        require(direction == -1 || direction == 1);

        int displacementChange = (int(msg.value) * direction * int(decayRatePerEther)) / 1 ether;
        int newDisplacement = getCurrentDisplacement() + displacementChange;
        int newLargestDisplacement = getProjectedDisplacement();

        currentDisplacement = newDisplacement;
        largestDisplacement = newLargestDisplacement;

        if (-currentDisplacement > largestDisplacement) {
            largestDisplacement = -currentDisplacement;
        } else if (currentDisplacement > largestDisplacement) {
            largestDisplacement = currentDisplacement;
        }

        lastUpdate = now;
    }

    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
}