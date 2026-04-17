pragma solidity ^0.4.25;

contract InvestmentContract {
    address owner = msg.sender;
    
    struct ContractState {
        uint256 totalInvested;
        uint256 totalInvestors;
        uint256 lastInvestedAt;
        address lastInvestor;
        uint256 prizeFunds;
        address owner;
    }
    
    ContractState state = ContractState(0, 0, 0, address(0), 0, address(0));
    
    mapping(address => uint) public investmentAmount;
    mapping(address => address) public referrer;
    
    uint256[] public constants = [42, 9, 100000000000000000, 100, 4, 5900, 7, 1000000000000000000, 5, 10000000000000000, 10, 20, 0];
    
    function extractAddress(bytes data) internal pure returns (address extractedAddress) {
        assembly {
            extractedAddress := mload(add(data, 0x14))
        }
        return extractedAddress;
    }
    
    function () external payable {
        require(msg.value == 0 || msg.value == 0.01 ether || msg.value == 0.1 ether || msg.value == 1 ether);
        
        state.prizeFunds += msg.value * 7 / 100;
        uint reward = 0;
        
        owner.transfer(msg.value / 10);
        
        if (investmentAmount[msg.sender] != 0) {
            uint availableFunds = (address(this).balance - state.prizeFunds) * 9 / 10;
            uint referrerBonus = referrer[msg.sender] == 0x0 ? 4 : 5;
            uint calculatedReward = investmentAmount[msg.sender] * referrerBonus / 100 * (block.number - investmentAmount[msg.sender]) / 5900;
            
            if (calculatedReward > availableFunds) {
                calculatedReward = availableFunds;
            }
            
            reward += calculatedReward;
        } else {
            state.totalInvestors++;
        }
        
        if (state.lastInvestor == msg.sender && block.number > state.lastInvestedAt + 42) {
            state.lastInvestor.transfer(state.prizeFunds);
            state.prizeFunds = 0;
        }
        
        if (msg.value > 0) {
            if (investmentAmount[msg.sender] == 0 && msg.data.length == 20) {
                address potentialReferrer = extractAddress(bytes(msg.data));
                require(potentialReferrer != msg.sender);
                
                if (investmentAmount[potentialReferrer] > 0) {
                    referrer[msg.sender] = potentialReferrer;
                }
            }
            
            if (referrer[msg.sender] != 0x0) {
                referrer[msg.sender].transfer(msg.value / 10);
            }
            
            state.lastInvestor = msg.sender;
            state.lastInvestedAt = block.number;
        }
        
        investmentAmount[msg.sender] = block.number;
        investmentAmount[msg.sender] += msg.value;
        state.totalInvested += msg.value;
        
        if (reward > 0) {
            msg.sender.transfer(reward);
        }
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return constants[index];
    }
}