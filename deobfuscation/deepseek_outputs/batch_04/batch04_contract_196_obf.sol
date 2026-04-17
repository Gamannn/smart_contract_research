```solidity
pragma solidity ^0.4.24;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Crowdsale {
    mapping(address => uint256) public balances;
    bool public picops_enabled;
    bool public sale_finalized;
    uint256 public total_raised;
    uint256 public constant max_raised_amount = 20 ether;
    uint256 public constant min_raise_amount = 1 ether;
    uint256 public constant picops_block_constant = 120;
    uint256 public constant fee_percent = 2;
    uint256 public constant fee_divisor = 100;
    
    address public creator;
    address public picops_address;
    address public sale_address;
    address public fee_address;
    
    uint256 public sale_start_block;
    uint256 public drain_block;
    uint256 public token_price_numerator;
    
    constructor() public {
        creator = msg.sender;
        fee_address = 0x5777c72Fb022DdF1185D3e2C7BB858862c134080;
        picops_enabled = false;
        sale_finalized = false;
        sale_start_block = 0;
        drain_block = 0;
        token_price_numerator = 0;
        total_raised = 0;
    }
    
    function startSale() public {
        require(sale_address == address(0));
        require(msg.sender == creator);
        require(picops_enabled);
        sale_start_block = block.number;
        sale_finalized = false;
    }
    
    function buyTokens(address tokenAddress) public {
        require(sale_finalized);
        ERC20 token = ERC20(tokenAddress);
        uint256 token_balance = token.balanceOf(address(this));
        require(token_balance != 0);
        
        uint256 tokens_to_send = (balances[msg.sender] * token_balance) / token_price_numerator;
        balances[msg.sender] = 0;
        
        uint256 fee_amount = tokens_to_send / 100;
        uint256 actual_fee = fee_amount * 2;
        
        require(token.transfer(msg.sender, tokens_to_send - actual_fee));
        require(token.transfer(fee_address, fee_amount));
        require(token.transfer(creator, fee_amount));
    }
    
    function refund() public {
        require(picops_enabled);
        uint256 eth_to_refund = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(eth_to_refund);
    }
    
    function finalizeSale() public {
        require(this.balance > min_raise_amount);
        require(!sale_finalized);
        token_price_numerator = this.balance;
        sale_finalized = true;
        sale_address.transfer(this.balance);
    }
    
    function enablePicops(bool enable) public {
        require(msg.sender == fee_address);
        require(token_price_numerator == 0);
        require(sale_address != address(0));
        if (!picops_enabled) {
            require(picops_enabled);
        }
        picops_enabled = enable;
    }
    
    function setDrainBlock(uint256 _drain_block) public {
        require(msg.sender == creator);
        require(picops_enabled);
        require(sale_address == address(0));
        drain_block = _drain_block;
    }
    
    function togglePicops() public {
        require(msg.sender == creator);
        picops_enabled = !picops_enabled;
    }
    
    function setFeeAddress(address _fee_address) public {
        require(msg.sender == fee_address);
        fee_address = _fee_address;
    }
    
    function setSaleAddress(address _sale_address) public {
        require(msg.sender == fee_address);
        require(sale_address == address(0));
        require(!sale_finalized);
        sale_address = _sale_address;
    }
    
    function setPicopsAddress(address _picops_address) public {
        require(msg.sender == fee_address);
        picops_address = _picops_address;
    }
    
    function drainTokens(address tokenAddress) public {
        require(msg.sender == fee_address);
        require(sale_finalized);
        require(block.number >= drain_block);
        
        ERC20 token = ERC20(tokenAddress);
        uint256 token_balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, token_balance));
    }
    
    function() external payable {
        require(!sale_finalized);
        
        if (!picops_enabled) {
            require(block.number >= (sale_start_block + picops_block_constant));
            picops_address = msg.sender;
        } else {
            require(this.balance < max_raised_amount);
            balances[msg.sender] += msg.value;
            total_raised += msg.value;
        }
    }
}
```