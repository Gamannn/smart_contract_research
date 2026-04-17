```solidity
pragma solidity ^0.4.25;

interface IExternalContract {
    function() payable external;
    function deposit(address recipient) payable external returns(uint256);
    function withdraw() external;
    function emergencyWithdraw() payable external;
    function claimRewards() payable external;
    function setRewardRate(uint256 rate) external;
    function transfer(address recipient, uint256 amount) external returns(bool);
    function pause() external;
    function unpause() external;
    function getBalance() external returns(uint256);
    function setFlag(bool flag) external;
    function calculateReward(address recipient) external pure returns(uint256);
    function updateRecipient(address recipient) external;
    function depositAndReturn(address recipient) payable external returns (uint256);
    function reset() external;
    function setLimit(uint256 limit) external;
    function calculateLimit(uint256 limit) external returns(uint256);
    function updateLimit(uint256 limit, address recipient) external;
}

contract MainContract {
    using SafeMath for uint;

    address constant projectManager = 0x0a97094c19295E320D5121d72139A150021a2702;
    IExternalContract constant externalContract = IExternalContract(0x0a97094c19295E320D5121d72139A150021a2702);

    mapping(address => uint) public userBalances;
    mapping(address => uint) public lastDepositTime;
    mapping(address => uint) public pendingRewards;

    uint constant rewardInterval = 1 hours;
    uint constant baseRewardRate = 270;

    function handleDeposit() internal {
        if (msg.value > 0) {
            if (now > lastDepositTime[msg.sender].add(rewardInterval)) {
                userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
                lastDepositTime[msg.sender] = now;
                processRewards();
            }
        }
    }

    function processRewards() internal {
        uint reward = 0;
        if (userBalances[msg.sender].mul(92).div(100) > calculateReward()) {
            reward = userBalances[msg.sender].mul(92).div(100);
            pendingRewards[msg.sender] = 0;
            userBalances[msg.sender] = 0;
            lastDepositTime[msg.sender] = 0;
            msg.sender.transfer(reward);
        } else {
            reward = calculateReward();
            pendingRewards[msg.sender] += reward;
            userBalances[msg.sender] = 0;
            lastDepositTime[msg.sender] = 0;
            msg.sender.transfer(reward);
        }
    }

    function processInvestment() internal {
        externalContract.deposit.value(msg.value.mul(rewardInterval).div(100))(projectManager);
        externalContract.setRewardRate(totalEthereumBalance());
    }

    function calculateReward() public view returns(uint) {
        uint currentRate = getCurrentRate();
        uint timeElapsed = now.sub(lastDepositTime[msg.sender]).div(rewardInterval);
        uint reward = userBalances[msg.sender].mul(currentRate).div(100000);
        uint calculatedReward = reward.mul(timeElapsed);
        if (calculatedReward > userBalances[msg.sender].mul(2)) {
            return userBalances[msg.sender].mul(2);
        }
        return calculatedReward;
    }

    function getCurrentRate() public view returns(uint) {
        uint contractBalance = address(this).balance;
        if (contractBalance < 4000 ether) {
            return baseRewardRate;
        }
        if (contractBalance >= 4000 ether && contractBalance < 1500 ether) {
            return baseRewardRate;
        }
        if (contractBalance >= 1500 ether && contractBalance < 400 ether) {
            return baseRewardRate;
        }
        if (contractBalance >= 400 ether) {
            return baseRewardRate;
        }
    }

    function totalEthereumBalance() public view returns(uint) {
        return address(this).balance;
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
```