```solidity
pragma solidity 0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    string public constant name = "OnUp TOKEN";
    string public constant symbol = "OnUp";
    uint256 public totalSupply = 700000000;
    uint256 public totalSold;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    
    function balanceOf(address owner) public constant returns (uint) {
        return balanceOf[owner];
    }
    
    function approve(address spender, uint value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }
    
    function allowance(address owner, address spender) public constant returns (uint remaining) {
        return allowance[owner][spender];
    }
}

contract OnUpToken is ERC20Basic {
    using SafeMath for uint256;
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
    mapping(address => address) public referrer;
    mapping(address => uint256) public userLevel;
    mapping(address => uint256) public totalInvested;
    
    constructor() payable public {
        data.owner = msg.sender;
        userLevel[data.fundAddress] = 6;
        userLevel[data.owner] = 6;
    }
    
    function() payable public {
        require(isContract(msg.sender) == false);
        require(msg.value >= 10000000000000000);
        require(msg.value <= 30000000000000000000);
        
        if (msg.sender != data.burnAddress) {
            data.referrer1 = address(0);
            data.referrer2 = address(0);
            data.referrer3 = address(0);
            data.referrer4 = address(0);
            data.referrer5 = address(0);
            
            if (msg.sender != data.fundAddress && msg.sender != data.owner) {
                processInvestment();
            } else {
                processDirectInvestment();
            }
        } else {
            data.totalEther = data.totalEther.add(msg.value.div(100).mul(90));
            data.tokenPrice = data.totalEther.div(data.totalSold);
        }
    }
    
    function processInvestment() internal {
        if (msg.value >= 25000000000000000000 && userLevel[msg.sender] < 6) {
            userLevel[msg.sender] = 6;
        }
        if (msg.value >= 20000000000000000000 && userLevel[msg.sender] < 5) {
            userLevel[msg.sender] = 5;
        }
        if (msg.value >= 15000000000000000000 && userLevel[msg.sender] < 4) {
            userLevel[msg.sender] = 4;
        }
        if (msg.value >= 10000000000000000000 && userLevel[msg.sender] < 3) {
            userLevel[msg.sender] = 3;
        }
        if (msg.value >= 5000000000000000000 && userLevel[msg.sender] < 2) {
            userLevel[msg.sender] = 2;
        }
        if (msg.value >= 100000000000000000 && userLevel[msg.sender] < 1) {
            userLevel[msg.sender] = 1;
        }
        
        if (totalInvested[msg.sender] >= 250000000000000000000 && userLevel[msg.sender] < 6) {
            userLevel[msg.sender] = 6;
        }
        if (totalInvested[msg.sender] >= 200000000000000000000 && userLevel[msg.sender] < 5) {
            userLevel[msg.sender] = 5;
        }
        if (totalInvested[msg.sender] >= 150000000000000000000 && userLevel[msg.sender] < 4) {
            userLevel[msg.sender] = 4;
        }
        if (totalInvested[msg.sender] >= 100000000000000000000 && userLevel[msg.sender] < 3) {
            userLevel[msg.sender] = 3;
        }
        if (totalInvested[msg.sender] >= 50000000000000000000 && userLevel[msg.sender] < 2) {
            userLevel[msg.sender] = 2;
        }
        
        data.referrer1 = referrer[msg.sender];
        if (data.referrer1 == address(0)) {
            data.referrer1 = bytesToAddress(msg.data);
            require(isContract(data.referrer1) == false);
            require(balanceOf[data.referrer1] > 0);
            require(data.referrer1 != data.tokenAddress);
            require(data.referrer1 != data.burnAddress);
            referrer[msg.sender] = data.referrer1;
        }
        
        processDirectInvestment();
    }
    
    function processDirectInvestment() internal {
        uint256 tokensToBuy = msg.value.div(data.tokenPrice.mul(100).div(70));
        require(tokensToBuy > 0);
        require(balanceOf[msg.sender].add(tokensToBuy) > balanceOf[msg.sender]);
        
        uint256 onePercent = msg.value.div(100);
        uint256 remainingForDistribution = onePercent.mul(10);
        
        uint256 tokensForReserve = 0;
        uint256 commission1 = 0;
        uint256 commission2 = 0;
        uint256 commission3 = 0;
        uint256 commission4 = 0;
        uint256 commission5 = 0;
        uint256 commission6 = 0;
        uint256 distributionPercent = 10;
        uint256 tokensForTokenPool = 0;
        
        if (msg.sender != data.fundAddress && msg.sender != data.owner && msg.sender != data.tokenAddress) {
            if (data.referrer1 != address(0)) {
                totalInvested[data.referrer1] = totalInvested[data.referrer1].add(msg.value);
                
                if (totalInvested[data.referrer1] >= 250000000000000000000 && userLevel[data.referrer1] < 6) {
                    userLevel[data.referrer1] = 6;
                }
                if (totalInvested[data.referrer1] >= 200000000000000000000 && userLevel[data.referrer1] < 5) {
                    userLevel[data.referrer1] = 5;
                }
                if (totalInvested[data.referrer1] >= 150000000000000000000 && userLevel[data.referrer1] < 4) {
                    userLevel[data.referrer1] = 4;
                }
                if (totalInvested[data.referrer1] >= 100000000000000000000 && userLevel[data.referrer1] < 3) {
                    userLevel[data.referrer1] = 3;
                }
                if (totalInvested[data.referrer1] >= 50000000000000000000 && userLevel[data.referrer1] < 2) {
                    userLevel[data.referrer1] = 2;
                }
                
                if (referrer[data.referrer1] != address(0)) {
                    data.referrer2 = referrer[data.referrer1];
                }
                if (referrer[data.referrer2] != address(0)) {
                    data.referrer3 = referrer[data.referrer2];
                }
                if (referrer[data.referrer3] != address(0)) {
                    data.referrer4 = referrer[data.referrer3];
                }
                if (referrer[data.referrer4] != address(0)) {
                    data.referrer5 = referrer[data.referrer4];
                }
                
                if (userLevel[data.referrer1] > 1) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent);
                    commission1 = onePercent.mul(2);
                    distributionPercent = distributionPercent.sub(2);
                } else if (userLevel[data.referrer1] > 0) {
                    commission1 = onePercent;
                    distributionPercent = distributionPercent.sub(1);
                }
            }
            
            if (data.referrer2 != address(0)) {
                if (userLevel[data.referrer2] > 2) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent.mul(2));
                    commission2 = onePercent.mul(2);
                    distributionPercent = distributionPercent.sub(2);
                } else if (userLevel[data.referrer2] > 0) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent);
                    commission2 = onePercent;
                    distributionPercent = distributionPercent.sub(1);
                }
            }
            
            if (data.referrer3 != address(0)) {
                if (userLevel[data.referrer3] > 3) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent.mul(2));
                    commission3 = onePercent.mul(2);
                    distributionPercent = distributionPercent.sub(2);
                } else if (userLevel[data.referrer3] > 0) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent);
                    commission3 = onePercent;
                    distributionPercent = distributionPercent.sub(1);
                }
            }
            
            if (data.referrer4 != address(0)) {
                if (userLevel[data.referrer4] > 4) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent.mul(2));
                    commission4 = onePercent.mul(2);
                    distributionPercent = distributionPercent.sub(2);
                } else if (userLevel[data.referrer4] > 0) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent);
                    commission4 = onePercent;
                    distributionPercent = distributionPercent.sub(1);
                }
            }
            
            if (data.referrer5 != address(0)) {
                if (userLevel[data.referrer5] > 5) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent.mul(2));
                    commission5 = onePercent.mul(2);
                    distributionPercent = distributionPercent.sub(2);
                } else if (userLevel[data.referrer5] > 0) {
                    remainingForDistribution = remainingForDistribution.sub(onePercent);
                    commission5 = onePercent;
                    distributionPercent = distributionPercent.sub(1);
                }
            }
        }
        
        if (remainingForDistribution > 0) {
            tokensForTokenPool = remainingForDistribution.div(data.tokenPrice.mul(100).div(70));
            require(tokensForTokenPool > 0);
            tokensForReserve = remainingForDistribution.div(100);
            
            balanceOf[data.tokenAddress] = balanceOf[data.tokenAddress].add(tokensForTokenPool);
            emit Transfer(this, data.tokenAddress, tokensForTokenPool);
        }
        
        data.totalEther = data.totalEther.add((onePercent.add(tokensForReserve)).mul(85 - distributionPercent));
        data.totalSold = data.totalSold.add(tokensToBuy.add(tokensForTokenPool));
        data.tokenPrice = data.totalEther.div(data.totalSold);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokensToBuy);
        emit Transfer(this, msg.sender, tokensToBuy);
        
        tokensToBuy = 0;
        tokensForTokenPool = 0;
        
        data.owner.transfer(onePercent.mul(5));
        data.fundAddress.transfer(onePercent.mul(5));
        
        if (commission1 > 0) {
            data.referrer1.transfer(commission1);
        }
        if (commission2 > 0) {
            data.referrer2.transfer(commission2);
        }
        if (commission3 > 0) {
            data.referrer3.transfer(commission3);
        }
        if (commission4 > 0) {
            data.referrer4.transfer(commission4);
        }
        if (commission5 > 0) {
            data.referrer5.transfer(commission5);
        }
    }
    
    function transfer(address to, uint value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        
        if (to != address(this)) {
            if (msg.sender == data.tokenAddress) {
                require(value < 20000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
            emit Transfer(msg.sender, to, value);
        } else {
            require(msg.sender != data.tokenAddress);
            
            balanceOf[msg.sender] -= value;
            uint256 etherToSend = value.mul(data.tokenPrice);
            require(address(this).balance >= etherToSend);
            
            if (data.totalSold > value) {
                uint256 etherPerToken = (address(this).balance.sub(data.totalEther)).div(data.totalSold);
                data.totalEther = data.totalEther.sub(etherToSend);
                data.totalSold = data.totalSold.sub(value);
                data.totalEther = data.totalEther.add(etherPerToken.mul(value));
                data.tokenPrice = data.totalEther.div(data.totalSold);
                emit Transfer(msg.sender, to, value);
            }
            
            if (data.totalSold == value) {
                data.tokenPrice = address(this).balance.div(data.totalSold);
                data.tokenPrice = (data.tokenPrice.mul(101)).div(100);
                data.totalSold = 0;
                data.totalEther = 0;
                emit Transfer(msg.sender, to, value);
                data.owner.transfer(address(this).balance.sub(etherToSend));
            }
            
            msg.sender.transfer(etherToSend);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);
        
        if (to != address(this)) {
            if (msg.sender == data.tokenAddress) {
                require(value < 20000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            
            balanceOf[from] -= value;
            balanceOf[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
        } else {
            require(from != data.tokenAddress);
            
            balanceOf[from] -= value;
            uint256 etherToSend = value.mul(data.tokenPrice);
            require(address(this).balance >= etherToSend);
            
            if (data.totalSold > value) {
                uint256 etherPerToken = (address(this).balance.sub(data.totalEther)).div(data.totalSold);
                data.totalEther = data.totalEther.sub(etherToSend);
                data.totalSold = data.totalSold.sub(value);
                data.totalEther = data.totalEther.add(etherPerToken.mul(value));
                data.tokenPrice = data.totalEther.div(data.totalSold);
                emit Transfer(from, to, value);
                allowance[from][msg.sender] -= value;
            }
            
            if (data.totalSold == value) {
                data.tokenPrice = address(this).balance.div(data.totalSold);
                data.tokenPrice = (data.tokenPrice.mul(101)).div(100);
                data.totalSold = 0;
                data.totalEther = 0;
                emit Transfer(from, to, value);
                allowance[from][msg.sender] -= value;
                data.owner.transfer(address(this).balance.sub(etherToSend));
            }
            
            from.transfer(etherToSend);
        }
        return true;
    }
    
    function bytesToAddress(bytes data) internal pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    struct ContractData {
        address tokenAddress;
        address fundAddress;
        address burnAddress;
        address owner;
        address referrer5;
        address referrer4;
        address referrer3;
        address referrer2;
        address referrer1;
        uint256 totalSold;
        uint256 tokenPrice;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalEther;
    }
    
    ContractData data = ContractData(
        0x516e0deBB3dB8C2c087786CcF7653fa0991784b3,
        0x28fF20D2d413A346F123198385CCf16E15295351,
        0xaB85Cb1087ce716E11dC37c69EaaBc09d674575d,
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        0,
        700000000,
        6,
        "OnUp",
        "OnUp TOKEN",
        0
    );
}
```