pragma solidity ^0.4.18;

contract BaseContract {
    struct ContractState {
        uint256 minimumContribution;
        address owner;
        address authorizedCaller;
        address admin;
    }
    
    ContractState internal state = ContractState(0, msg.sender, msg.sender, address(0));

    function setAdmin(address newAdmin) public onlyAuthorized {
        state.admin = newAdmin;
    }

    function authorizeCaller() public {
        if (msg.sender == state.admin) {
            state.authorizedCaller = state.admin;
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

    function initializeContract() public {
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

    function transferContribution(address contributor, address tokenContract, uint amount) public onlyAuthorized {
        if (contributions[contributor] > 0) {
            contributions[contributor] = 0;
            transferTokens(tokenContract, amount, contributor);
        }
    }

    function withdrawContribution(address recipient, uint amount) public onlyAuthorized payable {
        if (contributions[msg.sender] > 0) {
            if (contributions[recipient] >= amount) {
                recipient.call.value(amount)();
                contributions[recipient] -= amount;
            }
        }
    }

    function getContractBalance() public constant returns (uint) {
        return this.balance;
    }
}