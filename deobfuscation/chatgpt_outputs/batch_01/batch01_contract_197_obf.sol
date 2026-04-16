```solidity
pragma solidity ^0.4.11;

contract DaoCasinoToken {
    function proxyPayment(address participant) payable;
    function transfer(address to, uint _amount) returns (bool success);
}

contract BetBuyer {
    mapping (address => uint256) public balances;
    mapping (address => bool) public checkedIn;
    DaoCasinoToken public token = DaoCasinoToken(0xFd08655DFcaD0d42B57Dc8f1dc8CC39eD8b6B071);

    struct ContractState {
        address developer;
        uint256 betPerEth;
        bool killSwitch;
        uint256 timeBought;
        bool boughtTokens;
        uint256 bounty;
        uint256 totalEthers;
        uint256 cap;
    }

    ContractState public state = ContractState(
        0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9,
        2000,
        false,
        0,
        false,
        0,
        0,
        0
    );

    function activateKillSwitch() {
        if (msg.sender != state.developer) throw;
        state.killSwitch = true;
    }

    function withdraw() {
        if (!state.boughtTokens) {
            uint256 ethAmount = balances[msg.sender];
            balances[msg.sender] = 0;
            msg.sender.transfer(ethAmount);
        } else {
            uint256 betAmount = balances[msg.sender] * state.betPerEth;
            balances[msg.sender] = 0;
            uint256 fee = 0;
            if (!checkedIn[msg.sender]) {
                fee = betAmount / 100;
                if (!token.transfer(state.developer, fee)) throw;
            }
            if (!token.transfer(msg.sender, betAmount - fee)) throw;
        }
    }

    function addToBounty() payable {
        if (msg.sender != state.developer) throw;
        if (state.killSwitch) throw;
        if (state.boughtTokens) throw;
        state.bounty += msg.value;
    }

    function claimBounty() {
        if (state.boughtTokens) return;
        if (state.killSwitch) throw;
        state.boughtTokens = true;
        state.timeBought = now;
        token.proxyPayment.value(this.balance - state.bounty)(address(this));
        msg.sender.transfer(state.bounty);
    }

    function defaultHelper() payable {
        if (msg.value <= 1 finney) {
            if (state.boughtTokens && token.totalEthers() < token.CAP()) {
                checkedIn[msg.sender] = true;
            } else {
                withdraw();
            }
        } else {
            if (state.killSwitch) throw;
            if (state.boughtTokens) throw;
            balances[msg.sender] += msg.value;
        }
    }

    function () payable {
        defaultHelper();
    }
}
```