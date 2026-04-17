```solidity
contract ERC20Interface {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract TokenSale {
    mapping (address => uint256) public bought_tokens;
    mapping (address => uint256) public user_balances;
    
    bool public sale_finalized;
    bool public contract_enabled;
    uint256 public contract_eth_value;
    uint256 constant public min_contribution = 20 ether;
    address constant public creator = 0x2E2E356b67d82D6f4F5D54FFCBcfFf4351D2e56c;
    address public verification_address = 0xf58546F5CDE2a7ff5C91AFc63B43380F0C198BE8;
    address public fee_address;
    
    bytes32 public verification_hash = 0x8d9b2b8f1327f8bad773f0f3af0cb4f3fbd8abfad8797a28d1d01e354982c7de;
    uint256 public creator_fee;
    
    uint256 public claim_block;
    uint256 public sale_end_block;
    
    ERC20Interface public token_contract;
    
    constructor(address _token_address) {
        token_contract = ERC20Interface(_token_address);
        contract_enabled = true;
        sale_end_block = 5350521;
        claim_block = 4722681;
        fee_address = creator;
    }
    
    function withdraw() {
        require(!sale_finalized);
        require(contract_enabled);
        
        uint256 token_balance = token_contract.balanceOf(address(this));
        require(token_balance != 0);
        
        uint256 tokens_to_withdraw = (bought_tokens[msg.sender] * token_balance) / contract_eth_value;
        contract_eth_value -= bought_tokens[msg.sender];
        bought_tokens[msg.sender] = 0;
        
        uint256 fee = tokens_to_withdraw / 100;
        uint256 user_amount = tokens_to_withdraw - fee;
        
        require(token_contract.transfer(msg.sender, user_amount));
        require(token_contract.transfer(fee_address, fee));
    }
    
    function refund() {
        require(!sale_finalized);
        require(bought_tokens[msg.sender] > 0);
        
        uint256 amount = bought_tokens[msg.sender];
        bought_tokens[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function finalize(bytes32 verification_code) {
        require(token_contract.balanceOf(address(this)) > min_contribution);
        require(!sale_finalized);
        require(verification_code == verification_hash || msg.sender == creator);
        
        sale_finalized = true;
        uint256 token_balance = token_contract.balanceOf(address(this));
        
        creator_fee = token_balance / 100;
        uint256 contract_value = token_balance - creator_fee;
        
        require(token_contract.transfer(creator, creator_fee));
        require(token_contract.transfer(verification_address, contract_value));
    }
    
    function enable_sale(bool enable) {
        require(msg.sender == creator);
        contract_enabled = enable;
    }
    
    function deposit() payable {
        if (!sale_finalized) {
            contract_eth_value += msg.value;
        }
    }
    
    function transfer(address to, uint256 amount) {
        require(user_balances[msg.sender] > 0);
        require(user_balances[msg.sender] >= amount);
        
        user_balances[msg.sender] -= amount;
        to.transfer(amount);
    }
    
    function withdraw_user_balance() {
        uint256 amount = user_balances[msg.sender];
        user_balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function set_verification(bool verify) {
        require(msg.sender == creator);
        sale_finalized = verify;
    }
    
    function set_verification_address(address new_address, bytes32 code) {
        require(keccak256(code) == verification_hash || msg.sender == creator);
        require(block.number > claim_block);
        verification_address = new_address;
    }
    
    function set_fee_address(address new_address) {
        require(msg.sender == creator);
        fee_address = new_address;
    }
    
    function set_sale_end(uint256 block_number) {
        require(block_number > sale_end_block);
        sale_end_block = block_number;
    }
    
    function set_claim_block(uint256 block_number) {
        require(block_number > claim_block);
        claim_block = block_number;
    }
    
    function retrieve_tokens(address token_address) {
        require(msg.sender == creator);
        require(block.number >= claim_block);
        
        ERC20Interface token = ERC20Interface(token_address);
        uint256 token_balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, token_balance));
    }
    
    function () payable {
        require(!sale_finalized);
        require(contract_enabled);
        bought_tokens[msg.sender] += msg.value;
    }
}
```