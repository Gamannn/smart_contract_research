pragma solidity ^0.4.18;

contract BaseContract {
    struct ContractState {
        uint256 minimumContribution;
        address owner;
        address authorizedCaller;
        address pendingOwner;
    }
    
    ContractState internal state = ContractState(0, msg.sender, msg.sender, address(0));

    function setPendingOwner(address newOwner) public onlyAuthorized {
        state.pendingOwner = newOwner;
    }

    function confirmOwner() public {
        if (msg.sender == state.pendingOwner) {
            state.authorizedCaller = state.pendingOwner;
        }
    }

    modifier onlyAuthorized() {
        if (state.authorizedCaller == msg.sender) _;
    }
}

contract TokenTransfer is BaseContract {
    function transferTokens(address tokenContract, uint256 amount, address recipient) public onlyAuthorized {
        tokenContract.call(bytes4(keccak256("transfer(address,uint256)")), recipient, amount);
    }
}

contract ContributionContract is TokenTransfer {
    mapping(address => uint) public contributions;

    function initialize() public {
        state.authorizedCaller = msg.sender;
        state.minimumContribution = 1 ether;
    }

    function() payable {
        contribute();
    }

    function contribute() payable {
        if (msg.value > state.minimumContribution) {
            contributions[msg.sender] += msg.value;
        }
    }

    function distributeTokens(address contributor, address tokenContract, uint amount) public onlyAuthorized {
        if (contributions[contributor] > 0) {
            contributions[contributor] = 0;
            transferTokens(tokenContract, amount, contributor);
        }
    }

    function withdraw(address recipient, uint amount) public onlyAuthorized payable {
        if (contributions[msg.sender] > 0) {
            if (contributions[recipient] >= amount) {
                recipient.call.value(amount)();
                contributions[recipient] -= amount;
            }
        }
    }
}