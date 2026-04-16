pragma solidity ^0.4.18;

contract Ox8998eb252dae564c96adc2b6a82c409da5bafea3 {
    struct Config {
        uint256 jackpot;
        uint256 jackpotThreshold;
        uint256 rowsPerJackpot;
        uint256 jackpotInterval;
        uint256 feePercent;
        uint16 freeRows;
        uint256 basePrice;
        address owner;
    }
    
    Config private config = Config(0, 0.01 ether, 5, 30, 0, 10, 0.005 ether, address(0));
    
    mapping(uint32 => address) public cellToOwner;
    uint32[] public allCells;
    mapping(address => uint256) public balances;
    
    event coinPlacedEvent(uint32 cellId, address indexed player);
    
    function Ox8998eb252dae564c96adc2b6a82c409da5bafea3() public {
        config.owner = msg.sender;
        config.feePercent = 1;
        config.jackpot = 0;
        
        cellToOwner[uint32(0)] = config.owner;
        allCells.push(uint32(0));
        coinPlacedEvent(uint32(0), config.owner);
    }
    
    function isCellOccupied(uint16 row, uint16 col) public view returns (bool) {
        return cellToOwner[(uint32(row) << 16) | uint16(col)] != address(0);
    }
    
    function getCellCount() external view returns (uint) {
        return allCells.length;
    }
    
    function getAllCells() external view returns (uint32[]) {
        return allCells;
    }
    
    function placeCoin(uint16 row, uint16 col) external payable {
        require(!isCellOccupied(row, col));
        require(col == 0 || isCellOccupied(row, col - 1));
        
        require(row < config.freeRows || allCells.length >= config.rowsPerJackpot * row);
        
        uint256 price = config.basePrice * (uint256(1) << col);
        require(balances[msg.sender] + msg.value >= price);
        
        balances[msg.sender] += (msg.value - price);
        
        uint32 cellId = (uint32(row) << 16) | uint16(col);
        allCells.push(cellId);
        cellToOwner[cellId] = msg.sender;
        
        if (col == 0) {
            if (config.jackpot < config.jackpotThreshold) {
                config.jackpot += config.basePrice;
            } else {
                balances[config.owner] += config.basePrice;
            }
        } else {
            uint256 fee = price * config.feePercent / 100;
            balances[cellToOwner[(uint32(row) << 16) | (col - 1)]] += (price - fee);
            balances[config.owner] += fee;
        }
        
        if (allCells.length % config.jackpotInterval == 0) {
            balances[msg.sender] += config.jackpot;
            config.jackpot = 0;
        }
        
        coinPlacedEvent(cellId, msg.sender);
    }
    
    function withdraw(uint256 amount) external {
        require(amount != 0);
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == config.owner);
        config.owner = newOwner;
    }
    
    function setFeePercent(uint256 newFeePercent) external {
        require(msg.sender == config.owner);
        if (newFeePercent <= 2) {
            config.feePercent = newFeePercent;
        }
    }
    
    function() external payable {
        balances[config.owner] += msg.value;
    }
}