pragma solidity ^0.4.17;

contract BaseContract {
    struct ContractState {
        uint256 totalBalance;
        address owner;
        address pendingOwner;
        address authorizedAddress;
        address payoutAddress;
    }

    ContractState state = ContractState(0, address(0), address(0), msg.sender, msg.sender);

    function isOwner() public constant returns (bool) {
        return state.owner == msg.sender;
    }

    function setPendingOwner(address newOwner) public {
        if (isOwner()) {
            state.pendingOwner = newOwner;
        }
    }

    function confirmOwner() public {
        if (msg.sender == state.pendingOwner) {
            state.owner = state.pendingOwner;
        }
    }

    function payout(uint amount) public {
        if (msg.sender == state.payoutAddress) {
            state.payoutAddress.transfer(amount);
        }
    }
}

contract DerivedContract is BaseContract {
    mapping(address => uint) public balances;

    function DerivedContract() public {
        state.owner = msg.sender;
    }

    function deposit() public payable {
        if (msg.value >= 1 ether) {
            balances[msg.sender] += msg.value;
            state.totalBalance += msg.value;
        }
    }

    function() public payable {
        deposit();
    }

    function transferFunds(address recipient, uint amount) public {
        if (balances[recipient] > 0) {
            if (isOwner()) {
                if (recipient.send(amount)) {
                    if (state.totalBalance >= amount) {
                        state.totalBalance -= amount;
                    } else {
                        state.totalBalance = 0;
                    }
                }
            }
        }
    }
}