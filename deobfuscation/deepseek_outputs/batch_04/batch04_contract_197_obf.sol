pragma solidity ^0.4.13;

interface Token {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract Sale {
    mapping (address => uint256) public bought_tokens;
    mapping (address => uint256) public refund_eth_value;
    
    bool public sale_active;
    bool public token_set;
    uint256 public contract_eth_value;
    uint256 public refund_contract_eth_value;
    uint256 public eth_minimum;
    bool public kill_switch;
    
    bytes32 password_hash = 0x8bf0720c6e610aace867eba51b03ab8ca908b665898b10faddc95a96e829539d;
    address public developer;
    address public token_address;
    Token public token;
    
    function set_token_address(address _token_address) {
        require(msg.sender == developer);
        token_address = _token_address;
        token = Token(_token_address);
        token_set = true;
    }
    
    function set_kill_switch(string password) {
        require(msg.sender == developer || sha3(password) == password_hash);
        kill_switch = true;
    }
    
    function withdraw(string password, uint256 amount) {
        require(msg.sender == developer || sha3(password) == password_hash);
        msg.sender.transfer(amount);
    }
    
    function withdraw_tokens(address _token_address) {
        Token _token = Token(_token_address);
        if (bought_tokens[msg.sender] == 0) return;
        require(msg.sender != token_address);
        
        if (!sale_active) {
            uint256 eth_to_withdraw = bought_tokens[msg.sender];
            bought_tokens[msg.sender] = 0;
            msg.sender.transfer(eth_to_withdraw);
        } else {
            uint256 token_balance = _token.balanceOf(address(this));
            require(token_balance != 0);
            uint256 tokens = (bought_tokens[msg.sender] * token_balance) / contract_eth_value;
            contract_eth_value -= bought_tokens[msg.sender];
            bought_tokens[msg.sender] = 0;
            uint256 fee = tokens / 100;
            require(_token.transfer(developer, fee));
            require(_token.transfer(msg.sender, tokens - fee));
        }
    }
    
    function refund() {
        require(refund_contract_eth_value != 0);
        require(refund_eth_value[msg.sender] != 0);
        uint256 eth_to_withdraw = (refund_eth_value[msg.sender] * refund_contract_eth_value) / contract_eth_value;
        refund_contract_eth_value -= refund_eth_value[msg.sender];
        refund_eth_value[msg.sender] = 0;
        msg.sender.transfer(eth_to_withdraw);
    }
    
    function () payable {
        if (!sale_active) {
            bought_tokens[msg.sender] += msg.value;
            refund_eth_value[msg.sender] += msg.value;
            if (this.balance < eth_minimum) return;
            if (kill_switch) return;
            require(token_address != 0x0);
            sale_active = true;
            contract_eth_value = this.balance;
            refund_contract_eth_value = contract_eth_value;
            require(token.balanceOf(address(this)) != 0);
        } else {
            require(msg.sender == token_address);
            refund_contract_eth_value += msg.value;
        }
    }
    
    function Sale() {
        developer = 0x0e7CE7D6851F60A1eF2CAE9cAD765a5a62F32A84;
        token_address = address(0);
        sale_active = false;
        token_set = false;
        kill_switch = false;
        contract_eth_value = 0;
        refund_contract_eth_value = 0;
        eth_minimum = 3235 ether;
    }
}