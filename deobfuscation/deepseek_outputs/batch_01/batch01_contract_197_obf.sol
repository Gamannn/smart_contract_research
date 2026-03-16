```solidity
pragma solidity ^0.4.11;

contract DaoCasinoToken {
    function proxyPayment(address participant) payable;
    function transfer(address to, uint amount) returns (bool success);
}

contract BetBuyer {
    mapping(address => uint256) public balances;
    mapping(address => bool) public checked_in;
    
    DaoCasinoToken public token = DaoCasinoToken(0xFd08655DFcaD0d42B57Dc8f1dc8CC39eD8b6B071);
    
    struct ContractState {
        address developer;
        uint256 bet_per_eth;
        bool kill_switch;
        uint256 time_bought;
        bool bought_tokens;
        uint256 bounty;
        uint256 totalEthers;
        uint256 CAP;
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
    
    function activate_kill_switch() {
        if (msg.sender != state.developer) revert();
        state.kill_switch = true;
    }
    
    function withdraw() {
        if (!state.bought_tokens) {
            uint256 eth_amount = balances[msg.sender];
            balances[msg.sender] = 0;
            msg.sender.transfer(eth_amount);
        } else {
            uint256 bet_amount = balances[msg.sender] * state.bet_per_eth;
            balances[msg.sender] = 0;
            uint256 fee = 0;
            
            if (!checked_in[msg.sender]) {
                fee = bet_amount / 100;
                if (!token.transfer(state.developer, fee)) revert();
            }
            
            if (!token.transfer(msg.sender, bet_amount - fee)) revert();
        }
    }
    
    function add_to_bounty() payable {
        if (msg.sender != state.developer) revert();
        if (state.kill_switch) revert();
        if (state.bought_tokens) revert();
        state.bounty += msg.value;
    }
    
    function claim_bounty() {
        if (state.bought_tokens) return;
        if (state.kill_switch) revert();
        
        state.bought_tokens = true;
        state.time_bought = now;
        
        token.proxyPayment.value(address(this).balance - state.bounty)(address(this));
        msg.sender.transfer(state.bounty);
    }
    
    function default_helper() payable {
        if (msg.value <= 1 finney) {
            if (state.bought_tokens && token.totalEthers() < token.CAP()) {
                checked_in[msg.sender] = true;
            } else {
                withdraw();
            }
        } else {
            if (state.kill_switch) revert();
            if (state.bought_tokens) revert();
            balances[msg.sender] += msg.value;
        }
    }
    
    function () payable {
        default_helper();
    }
}
```