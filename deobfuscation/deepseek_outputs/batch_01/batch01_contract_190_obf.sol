```solidity
pragma solidity ^0.4.25;

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
    uint8 public constant decimals = 6;
    
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
    mapping(address => uint256) public level;
    mapping(address => uint256) public totalInvested;
    
    constructor() public payable {
        data.owner = msg.sender;
        level[data.fundAddress] = 6;
        level[data.owner] = 6;
    }
    
    function() payable public {
        require(msg.value >= 10000000000000000);
        require(msg.value <= 30000000000000000000);
        require(isContract(msg.sender) == false);
        
        if (msg.sender != data.teamAddress) {
            data.referrer1 = address(0);
            data.referrer2 = address(0);
            data.referrer3 = address(0);
            data.referrer4 = address(0);
            data.referrer5 = address(0);
            
            if (msg.sender != data.fundAddress && msg.sender != data.owner && msg.sender != data.tokenAddress) {
                processInvestment();
            } else {
                processDirectInvestment();
            }
        } else {
            data.totalFund = data.totalFund.add(msg.value.div(100).mul(90));
            data.tokenPrice = data.totalFund.div(data.totalSupply);
        }
    }
    
    function processInvestment() internal {
        if (msg.value >= 25000000000000000000 && level[msg.sender] < 6) {
            level[msg.sender] = 6;
        }
        if (msg.value >= 20000000000000000000 && level[msg.sender] < 5) {
            level[msg.sender] = 5;
        }
        if (msg.value >= 15000000000000000000 && level[msg.sender] < 4) {
            level[msg.sender] = 4;
        }
        if (msg.value >= 10000000000000000000 && level[msg.sender] < 3) {
            level[msg.sender] = 3;
        }
        if (msg.value >= 5000000000000000000 && level[msg.sender] < 2) {
            level[msg.sender] = 2;
        }
        if (msg.value >= 100000000000000000 && level[msg.sender] < 1) {
            level[msg.sender] = 1;
        }
        
        if (totalInvested[msg.sender] >= 250000000000000000000 && level[msg.sender] < 6) {
            level[msg.sender] = 6;
        }
        if (totalInvested[msg.sender] >= 200000000000000000000 && level[msg.sender] < 5) {
            level[msg.sender] = 5;
        }
        if (totalInvested[msg.sender] >= 150000000000000000000 && level[msg.sender] < 4) {
            level[msg.sender] = 4;
        }
        if (totalInvested[msg.sender] >= 100000000000000000000 && level[msg.sender] < 3) {
            level[msg.sender] = 3;
        }
        if (totalInvested[msg.sender] >= 50000000000000000000 && level[msg.sender] < 2) {
            level[msg.sender] = 2;
        }
        
        data.referrer1 = referrer[msg.sender];
        
        if (data.referrer1 == address(0)) {
            data.referrer1 = bytesToAddress(msg.data);
            require(isContract(data.referrer1) == false);
            require(balanceOf[data.referrer1] > 0);
            require(data.referrer1 != data.tokenAddress);
            require(data.referrer1 != data.teamAddress);
            referrer[msg.sender] = data.referrer1;
        }
        
        processDirectInvestment();
    }
    
    function processDirectInvestment() internal {
        uint256 tokensToMint = msg.value.div(data.tokenPrice.mul(100).div(70));
        require(tokensToMint > 0);
        require(balanceOf[msg.sender].add(tokensToMint) > balanceOf[msg.sender]);
        
        uint256 onePercent = msg.value.div(100);
        uint256 tenPercent = onePercent.mul(10);
        
        uint256 remainingForDistribution = 0;
        uint256 referrer1Bonus = 0;
        uint256 referrer2Bonus = 0;
        uint256 referrer3Bonus = 0;
        uint256 referrer4Bonus = 0;
        uint256 referrer5Bonus = 0;
        uint256 referrer6Bonus = 0;
        uint256 referrer7Bonus = 0;
        uint256 referrer8Bonus = 0;
        
        uint256 totalReferrers = 0;
        
        if (msg.sender != data.fundAddress && msg.sender != data.owner && msg.sender != data.tokenAddress) {
            if (data.referrer1 != address(0)) {
                totalInvested[data.referrer1] = totalInvested[data.referrer1].add(msg.value);
                
                if (level[data.referrer1] > 1) {
                    tenPercent = tenPercent.sub(onePercent.mul(2));
                    referrer1Bonus = onePercent.mul(2);
                    totalReferrers = totalReferrers.add(2);
                } else if (level[data.referrer1] > 0) {
                    tenPercent = tenPercent.sub(onePercent);
                    referrer1Bonus = onePercent;
                    totalReferrers = totalReferrers.add(1);
                }
                
                if (data.referrer2 != address(0)) {
                    if (level[data.referrer2] > 2) {
                        tenPercent = tenPercent.sub(onePercent.mul(2));
                        referrer2Bonus = onePercent.mul(2);
                        totalReferrers = totalReferrers.add(2);
                    } else if (level[data.referrer2] > 0) {
                        tenPercent = tenPercent.sub(onePercent);
                        referrer2Bonus = onePercent;
                        totalReferrers = totalReferrers.add(1);
                    }
                    
                    if (data.referrer3 != address(0)) {
                        if (level[data.referrer3] > 3) {
                            tenPercent = tenPercent.sub(onePercent.mul(2));
                            referrer3Bonus = onePercent.mul(2);
                            totalReferrers = totalReferrers.add(2);
                        } else if (level[data.referrer3] > 0) {
                            tenPercent = tenPercent.sub(onePercent);
                            referrer3Bonus = onePercent;
                            totalReferrers = totalReferrers.add(1);
                        }
                        
                        if (data.referrer4 != address(0)) {
                            if (level[data.referrer4] > 4) {
                                tenPercent = tenPercent.sub(onePercent.mul(2));
                                referrer4Bonus = onePercent.mul(2);
                                totalReferrers = totalReferrers.add(2);
                            } else if (level[data.referrer4] > 0) {
                                tenPercent = tenPercent.sub(onePercent);
                                referrer4Bonus = onePercent;
                                totalReferrers = totalReferrers.add(1);
                            }
                            
                            if (data.referrer5 != address(0)) {
                                if (level[data.referrer5] > 5) {
                                    tenPercent = tenPercent.sub(onePercent.mul(2));
                                    referrer5Bonus = onePercent.mul(2);
                                    totalReferrers = totalReferrers.add(2);
                                } else if (level[data.referrer5] > 0) {
                                    tenPercent = tenPercent.sub(onePercent);
                                    referrer5Bonus = onePercent;
                                    totalReferrers = totalReferrers.add(1);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (tenPercent > 0) {
            remainingForDistribution = tenPercent.div(data.tokenPrice.mul(100).div(70));
            require(remainingForDistribution > 0);
            
            uint256 remainingTokens = tenPercent.div(100);
            balanceOf[data.tokenAddress] = balanceOf[data.tokenAddress].add(remainingForDistribution);
            emit Transfer(this, data.tokenAddress, remainingForDistribution);
        }
        
        data.totalFund = data.totalFund.add(onePercent.add(remainingTokens).mul(85 - totalReferrers));
        data.totalSupply = data.totalSupply.add(tokensToMint.add(remainingForDistribution));
        data.tokenPrice = data.totalFund.div(data.totalSupply);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokensToMint);
        emit Transfer(this, msg.sender, tokensToMint);
        
        tokensToMint = 0;
        remainingForDistribution = 0;
        
        data.owner.transfer(onePercent.mul(5));
        data.fundAddress.transfer(onePercent.mul(5));
        
        if (referrer1Bonus > 0) {
            data.referrer1.transfer(referrer1Bonus);
        }
        if (referrer2Bonus > 0) {
            data.referrer2.transfer(referrer2Bonus);
        }
        if (referrer3Bonus > 0) {
            data.referrer3.transfer(referrer3Bonus);
        }
        if (referrer4Bonus > 0) {
            data.referrer4.transfer(referrer4Bonus);
        }
        if (referrer5Bonus > 0) {
            data.referrer5.transfer(referrer5Bonus);
        }
    }
    
    function transfer(address to, uint value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        
        if (to != address(this)) {
            if (msg.sender == data.tokenAddress) {
                require(value < 10000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            emit Transfer(msg.sender, to, value);
        } else {
            require(msg.sender != data.tokenAddress);
            
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            uint256 ethToSend = value.mul(data.tokenPrice);
            require(address(this).balance >= ethToSend);
            
            if (data.totalSupply > value) {
                uint256 remainingEthPerToken = (address(this).balance.sub(data.totalFund)).div(data.totalSupply);
                data.totalFund = data.totalFund.sub(ethToSend);
                data.totalSupply = data.totalSupply.sub(value);
                data.totalFund = data.totalFund.add(remainingEthPerToken.mul(value));
                data.tokenPrice = data.totalFund.div(data.totalSupply);
                emit Transfer(msg.sender, to, value);
            }
            
            if (data.totalSupply == value) {
                data.tokenPrice = address(this).balance.div(data.totalSupply);
                data.tokenPrice = data.tokenPrice.mul(101).div(100);
                data.totalSupply = 0;
                data.totalFund = 0;
                emit Transfer(msg.sender, to, value);
                data.owner.transfer(address(this).balance.sub(ethToSend));
            }
            
            msg.sender.transfer(ethToSend);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);
        
        if (to != address(this)) {
            if (msg.sender == data.tokenAddress) {
                require(value < 10000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            
            balanceOf[from] = balanceOf[from].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
        } else {
            require(from != data.tokenAddress);
            
            balanceOf[from] = balanceOf[from].sub(value);
            uint256 ethToSend = value.mul(data.tokenPrice);
            require(address(this).balance >= ethToSend);
            
            if (data.totalSupply > value) {
                uint256 remainingEthPerToken = (address(this).balance.sub(data.totalFund)).div(data.totalSupply);
                data.totalFund = data.totalFund.sub(ethToSend);
                data.totalSupply = data.totalSupply.sub(value);
                data.totalFund = data.totalFund.add(remainingEthPerToken.mul(value));
                data.tokenPrice = data.totalFund.div(data.totalSupply);
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            }
            
            if (data.totalSupply == value) {
                data.tokenPrice = address(this).balance.div(data.totalSupply);
                data.tokenPrice = data.tokenPrice.mul(101).div(100);
                data.totalSupply = 0;
                data.totalFund = 0;
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
                data.owner.transfer(address(this).balance.sub(ethToSend));
            }
            
            from.transfer(ethToSend);
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
        address teamAddress;
        address owner;
        address referrer5;
        address referrer4;
        address referrer3;
        address referrer2;
        address referrer1;
        uint256 totalSupply;
        uint256 tokenPrice;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalFund;
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