pragma solidity ^0.4.2;

contract Token {
    string public standard;
    string public name;
    string public symbol;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function Token(uint256 totalSupply, string _standard, string _name, string _symbol, uint8 _decimals) {
        s2c._totalSupply = totalSupply;
        balanceOf[this] = totalSupply;
        standard = _standard;
        name = _name;
        symbol = _symbol;
        s2c.decimals = _decimals;
    }
    
    function totalSupply() constant returns(uint256 supply) {
        return s2c._totalSupply;
    }
    
    function transferInternal(address from, address to, uint256 value) internal returns (bool success) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function transferFromInternal(address from, address to, uint256 value) internal returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        return transferInternal(from, to, value);
    }
}

contract ICO {
    event BonusEarned(address target, uint256 bonus);
    
    function calculateBonus(uint8 icoStep, uint256 totalSoldSlogns, uint256 soldSlogns) returns (uint256) {
        if(icoStep == 1) {
            return soldSlogns / 100 * s2c.PRE_ICO_BONUS_RATE;
        } else if(icoStep == 2) {
            if(totalSoldSlogns > s2c.ICO_BONUS1_SLGN_LESS + s2c.ICO_BONUS2_SLGN_LESS) {
                return 0;
            }
            uint256 availableForBonus1 = s2c.ICO_BONUS1_SLGN_LESS - totalSoldSlogns;
            uint256 tmp = soldSlogns;
            uint256 bonus = 0;
            uint256 tokensForBonus1 = 0;
            
            if(availableForBonus1 > 0 && availableForBonus1 <= s2c.ICO_BONUS1_SLGN_LESS) {
                tokensForBonus1 = tmp > availableForBonus1 ? availableForBonus1 : tmp;
                bonus += tokensForBonus1 / 100 * s2c.ICO_BONUS1_RATE;
                tmp -= tokensForBonus1;
            }
            
            uint256 availableForBonus2 = (s2c.ICO_BONUS2_SLGN_LESS + s2c.ICO_BONUS1_SLGN_LESS) - totalSoldSlogns - tokensForBonus1;
            uint256 tokensForBonus2 = 0;
            
            if(availableForBonus2 > 0 && availableForBonus2 <= s2c.ICO_BONUS2_SLGN_LESS) {
                tokensForBonus2 = tmp > availableForBonus2 ? availableForBonus2 : tmp;
                bonus += tokensForBonus2 / 100 * s2c.ICO_BONUS2_RATE;
                tmp -= tokensForBonus2;
            }
            
            return bonus;
        }
        return 0;
    }
}

contract EscrowICO is Token, ICO {
    mapping (address => uint256) public preIcoEthers;
    mapping (address => uint256) public icoEthers;
    
    event RefundEth(address indexed investor, uint256 amount);
    event IcoFinished();
    
    function EscrowICO() {
        s2c.isTransactionsAllowed = false;
    }
    
    function getIcoStep(uint256 time) returns (uint8 step) {
        if(time >= s2c.PRE_ICO_SINCE && time <= s2c.PRE_ICO_TILL) {
            return 1;
        } else if(time >= s2c.ICO_SINCE && time <= s2c.ICO_TILL) {
            if(s2c.totalSoldSlogns >= s2c.MIN_PRE_ICO_SLOGN_COLLECTED) {
                return 2;
            }
        }
        return 0;
    }
    
    function icoFinishInternal(uint256 time) internal returns (bool) {
        if(time <= s2c.ICO_TILL) {
            return false;
        }
        if(s2c.totalSoldSlogns >= s2c.MIN_ICO_SLOGN_COLLECTED) {
            s2c._totalSupply = s2c._totalSupply - balanceOf[this];
            balanceOf[this] = 0;
            s2c.isTransactionsAllowed = true;
            IcoFinished();
            return true;
        }
        return false;
    }
    
    function refundInternal(uint256 time) internal returns (bool) {
        if(time <= s2c.PRE_ICO_TILL) {
            return false;
        }
        if(s2c.totalSoldSlogns >= s2c.MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }
        uint256 transferedEthers = preIcoEthers[msg.sender];
        if(transferedEthers > 0) {
            preIcoEthers[msg.sender] = 0;
            balanceOf[msg.sender] = 0;
            msg.sender.transfer(transferedEthers);
            RefundEth(msg.sender, transferedEthers);
            return true;
        }
        return false;
    }
}

contract SlognToken is Token, EscrowICO {
    string public constant STANDARD = 'Slogn v0.1';
    string public constant NAME = 'SLOGN';
    string public constant SYMBOL = 'SLGN';
    
    event BonusEarned(address target, uint256 bonus);
    
    modifier onlyOwner() {
        require(s2c.owner == msg.sender);
        _;
    }
    
    function SlognToken(
        address [] coreTeam,
        address _advisoryBoardFundManager,
        address _opensourceFundManager,
        address _reserveFundManager,
        address _bountyFundManager,
        address _ethFundManager
    ) Token (s2c.TOTAL_SUPPLY, STANDARD, NAME, SYMBOL, s2c.PRECISION) EscrowICO() {
        s2c.owner = msg.sender;
        s2c.advisoryBoardFundManager = _advisoryBoardFundManager;
        s2c.opensourceFundManager = _opensourceFundManager;
        s2c.reserveFundManager = _reserveFundManager;
        s2c.bountyFundManager = _bountyFundManager;
        s2c.ethFundManager = _ethFundManager;
        
        uint256 tokensPerMember = s2c.CORE_TEAM_TOKENS / coreTeam.length;
        for(uint8 i = 0; i < coreTeam.length; i++) {
            transferInternal(this, coreTeam[i], tokensPerMember);
        }
        
        transferInternal(this, s2c.advisoryBoardFundManager, s2c.ADVISORY_BOARD_TOKENS);
        transferInternal(this, s2c.opensourceFundManager, s2c.OPENSOURCE_TOKENS);
        transferInternal(this, s2c.reserveFundManager, s2c.RESERVE_TOKENS);
        transferInternal(this, s2c.bountyFundManager, s2c.BOUNTY_TOKENS);
    }
    
    function buyFor(address _user, uint256 ethers, uint time) internal returns (bool success) {
        require(ethers > 0);
        uint8 icoStep = getIcoStep(time);
        require(icoStep == 1 || icoStep == 2);
        
        if(icoStep == 1 && (s2c.totalSoldSlogns + ethers) > 5000 ether) {
            throw;
        }
        
        uint256 slognAmount = ethers;
        uint256 bonus = calculateBonus(icoStep, s2c.totalSoldSlogns, slognAmount);
        
        require(balanceOf[this] >= slognAmount + bonus);
        
        if(bonus > 0) {
            BonusEarned(_user, bonus);
        }
        
        transferInternal(this, _user, slognAmount + bonus);
        s2c.totalSoldSlogns += slognAmount;
        
        if(icoStep == 1) {
            preIcoEthers[_user] += ethers;
        }
        if(icoStep == 2) {
            icoEthers[_user] += ethers;
        }
        return true;
    }
    
    function buy() payable {
        buyFor(msg.sender, msg.value, block.timestamp);
    }
    
    function transferEther(address to, uint256 amount) returns (bool success) {
        if(msg.sender != s2c.ethFundManager) {
            return false;
        }
        if(s2c.totalSoldSlogns < s2c.MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }
        if(this.balance < amount) {
            return false;
        }
        to.transfer(amount);
        return true;
    }
    
    function transfer(address to, uint256 value) returns (bool success) {
        if(s2c.isTransactionsAllowed == false) {
            if(msg.sender != s2c.bountyFundManager) {
                return false;
            }
        }
        return transferInternal(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if(s2c.isTransactionsAllowed == false) {
            if(from != s2c.bountyFundManager) {
                return false;
            }
        }
        return transferFromInternal(from, to, value);
    }
    
    function refund() returns (bool) {
        return refundInternal(block.timestamp);
    }
    
    function icoFinish() returns (bool) {
        return icoFinishInternal(block.timestamp);
    }
    
    function setPreIcoDates(uint256 since, uint256 till) onlyOwner {
        s2c.PRE_ICO_SINCE = since;
        s2c.PRE_ICO_TILL = till;
    }
    
    function setIcoDates(uint256 since, uint256 till) onlyOwner {
        s2c.ICO_SINCE = since;
        s2c.ICO_TILL = till;
    }
    
    function setTransactionsAllowed(bool enabled) onlyOwner {
        s2c.isTransactionsAllowed = enabled;
    }
    
    function () payable {
        throw;
    }
    
    struct Config {
        address owner;
        address ethFundManager;
        address bountyFundManager;
        address reserveFundManager;
        address opensourceFundManager;
        address advisoryBoardFundManager;
        uint256 BOUNTY_TOKENS;
        uint256 RESERVE_TOKENS;
        uint256 OPENSOURCE_TOKENS;
        uint256 ADVISORY_BOARD_TOKENS;
        uint256 CORE_TEAM_TOKENS;
        uint256 TOTAL_SUPPLY;
        uint8 PRECISION;
        uint256 totalSoldSlogns;
        bool isTransactionsAllowed;
        uint256 MIN_ICO_SLOGN_COLLECTED;
        uint256 MIN_PRE_ICO_SLOGN_COLLECTED;
        uint256 ICO_BONUS2_RATE;
        uint256 ICO_BONUS2_SLGN_LESS;
        uint256 ICO_BONUS1_RATE;
        uint256 ICO_BONUS1_SLGN_LESS;
        uint256 ICO_TILL;
        uint256 ICO_SINCE;
        uint256 PRE_ICO_SLGN_LESS;
        uint256 PRE_ICO_BONUS_RATE;
        uint256 PRE_ICO_TILL;
        uint256 PRE_ICO_SINCE;
        uint256 _totalSupply;
        uint8 decimals;
    }
    
    Config s2c = Config(
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        800000 ether / 100,
        800000 ether / 100 * 5,
        800000 ether / 1000 * 75,
        800000 ether / 1000 * 15,
        800000 ether / 100 * 15,
        800000 ether,
        14,
        0,
        false,
        1000 ether,
        1000 ether,
        15,
        50000 ether,
        30,
        20000 ether,
        1502809200,
        1500994800,
        5000 ether,
        70,
        1500476400,
        1500303600,
        0,
        0
    );
}