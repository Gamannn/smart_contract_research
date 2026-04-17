pragma solidity ^0.4.4;

contract Ox00ca297c7825940e107450d832688e9f153b5154 {
    struct Config {
        uint256 weiPerBlock;
        uint256 minBlockPurchase;
        address owner;
    }
    
    Config public config = Config(0, 0, address(0));
    
    mapping (address => uint256) public userExpirationBlock;
    
    function Ox00ca297c7825940e107450d832688e9f153b5154() {
        config.owner = msg.sender;
        config.weiPerBlock = 100000000000;
        config.minBlockPurchase = 4320;
    }
    
    function () payable {
        uint256 currentExpiration = userExpirationBlock[msg.sender];
        
        if (currentExpiration > 0 && currentExpiration < block.number) {
            userExpirationBlock[msg.sender] = currentExpiration + calculateBlocks(msg.value);
        } else {
            userExpirationBlock[msg.sender] = block.number + calculateBlocks(msg.value);
        }
    }
    
    function calculateBlocks(uint256 value) returns (uint256) {
        require(value >= config.minBlockPurchase);
        return value / config.weiPerBlock;
    }
    
    function setWeiPerBlock(uint256 newWeiPerBlock) {
        if (msg.sender == config.owner) {
            config.weiPerBlock = newWeiPerBlock;
        }
    }
    
    function setMinBlockPurchase(uint256 newMinBlockPurchase) {
        if (msg.sender == config.owner) {
            config.minBlockPurchase = newMinBlockPurchase;
        }
    }
    
    function withdraw(uint256 amount) {
        if (msg.sender == config.owner) {
            config.owner.transfer(amount);
        }
    }
}