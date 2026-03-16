```solidity
pragma solidity ^0.4.2;

contract Token {
    string public standard;
    string public name;
    string public symbol;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    struct TokenDetails {
        uint256 totalSupply;
        uint8 decimals;
    }

    TokenDetails public tokenDetails;

    function Token(uint256 initialSupply, string _standard, string _name, string _symbol, uint8 _decimals) public {
        tokenDetails.totalSupply = initialSupply;
        balanceOf[this] = initialSupply;
        standard = _standard;
        name = _name;
        symbol = _symbol;
        tokenDetails.decimals = _decimals;
    }

    function totalSupply() public constant returns (uint256 supply) {
        return tokenDetails.totalSupply;
    }

    function transferInternal(address from, address to, uint256 value) internal returns (bool success) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
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

    struct ICOConfig {
        uint256 PRE_ICO_BONUS_RATE;
        uint256 ICO_BONUS1_SLGN_LESS;
        uint256 ICO_BONUS2_SLGN_LESS;
        uint256 ICO_BONUS1_RATE;
        uint256 ICO_BONUS2_RATE;
    }

    ICOConfig public icoConfig;

    function calculateBonus(uint8 icoStep, uint256 totalSoldTokens, uint256 soldTokens) public returns (uint256) {
        if (icoStep == 1) {
            return soldTokens / 100 * icoConfig.PRE_ICO_BONUS_RATE;
        } else if (icoStep == 2) {
            if (totalSoldTokens > icoConfig.ICO_BONUS1_SLGN_LESS + icoConfig.ICO_BONUS2_SLGN_LESS) {
                return 0;
            }
            uint256 availableForBonus1 = icoConfig.ICO_BONUS1_SLGN_LESS - totalSoldTokens;
            uint256 tmp = soldTokens;
            uint256 bonus = 0;
            uint256 tokensForBonus1 = 0;
            if (availableForBonus1 > 0 && availableForBonus1 <= icoConfig.ICO_BONUS1_SLGN_LESS) {
                tokensForBonus1 = tmp > availableForBonus1 ? availableForBonus1 : tmp;
                bonus += tokensForBonus1 / 100 * icoConfig.ICO_BONUS1_RATE;
                tmp -= tokensForBonus1;
            }
            uint256 availableForBonus2 = (icoConfig.ICO_BONUS2_SLGN_LESS + icoConfig.ICO_BONUS1_SLGN_LESS) - totalSoldTokens - tokensForBonus1;
            uint256 tokensForBonus2 = 0;
            if (availableForBonus2 > 0 && availableForBonus2 <= icoConfig.ICO_BONUS2_SLGN_LESS) {
                tokensForBonus2 = tmp > availableForBonus2 ? availableForBonus2 : tmp;
                bonus += tokensForBonus2 / 100 * icoConfig.ICO_BONUS2_RATE;
                tmp -= tokensForBonus2;
            }
            return bonus;
        }
        return 0;
    }
}

contract EscrowICO is Token, ICO {
    mapping(address => uint256) public preIcoEthers;
    mapping(address => uint256) public icoEthers;

    event RefundEth(address indexed to, uint256 value);
    event IcoFinished();

    struct EscrowConfig {
        bool isTransactionsAllowed;
        uint256 MIN_PRE_ICO_SLOGN_COLLECTED;
        uint256 MIN_ICO_SLOGN_COLLECTED;
        uint256 totalSoldTokens;
        uint256 ICO_TILL;
        uint256 ICO_SINCE;
        uint256 PRE_ICO_TILL;
        uint256 PRE_ICO_SINCE;
    }

    EscrowConfig public escrowConfig;

    function EscrowICO() public {
        escrowConfig.isTransactionsAllowed = false;
    }

    function getIcoStep(uint256 time) public returns (uint8 step) {
        if (time >= escrowConfig.PRE_ICO_SINCE && time <= escrowConfig.PRE_ICO_TILL) {
            return 1;
        } else if (time >= escrowConfig.ICO_SINCE && time <= escrowConfig.ICO_TILL) {
            if (escrowConfig.totalSoldTokens >= escrowConfig.MIN_PRE_ICO_SLOGN_COLLECTED) {
                return 2;
            }
        }
        return 0;
    }

    function icoFinishInternal(uint256 time) internal returns (bool) {
        if (time <= escrowConfig.ICO_TILL) {
            return false;
        }
        if (escrowConfig.totalSoldTokens >= escrowConfig.MIN_ICO_SLOGN_COLLECTED) {
            tokenDetails.totalSupply = tokenDetails.totalSupply - balanceOf[this];
            balanceOf[this] = 0;
            escrowConfig.isTransactionsAllowed = true;
            IcoFinished();
            return true;
        }
        return false;
    }

    function refundInternal(uint256 time) internal returns (bool) {
        if (time <= escrowConfig.PRE_ICO_TILL) {
            return false;
        }
        if (escrowConfig.totalSoldTokens >= escrowConfig.MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }
        uint256 transferredEthers = preIcoEthers[msg.sender];
        if (transferredEthers > 0) {
            preIcoEthers[msg.sender] = 0;
            balanceOf[msg.sender] = 0;
            msg.sender.transfer(transferredEthers);
            RefundEth(msg.sender, transferredEthers);
            return true;
        }
        return false;
    }
}

contract SlognToken is Token, EscrowICO {
    string public constant STANDARD = 'Slogn v0.1';
    string public constant NAME = 'SLOGN';
    string public constant SYMBOL = 'SLGN';

    struct SlognConfig {
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
    }

    SlognConfig public slognConfig;

    event BonusEarned(address target, uint256 bonus);

    modifier onlyOwner() {
        require(slognConfig.owner == msg.sender);
        _;
    }

    function SlognToken(
        address[] coreTeam,
        address _advisoryBoardFundManager,
        address _opensourceFundManager,
        address _reserveFundManager,
        address _bountyFundManager,
        address _ethFundManager
    ) Token(
        800000 ether,
        STANDARD,
        NAME,
        SYMBOL,
        14
    ) EscrowICO() public {
        slognConfig.owner = msg.sender;
        slognConfig.advisoryBoardFundManager = _advisoryBoardFundManager;
        slognConfig.opensourceFundManager = _opensourceFundManager;
        slognConfig.reserveFundManager = _reserveFundManager;
        slognConfig.bountyFundManager = _bountyFundManager;
        slognConfig.ethFundManager = _ethFundManager;

        uint256 tokensPerMember = slognConfig.CORE_TEAM_TOKENS / coreTeam.length;
        for (uint8 i = 0; i < coreTeam.length; i++) {
            transferInternal(this, coreTeam[i], tokensPerMember);
        }
        transferInternal(this, slognConfig.advisoryBoardFundManager, slognConfig.ADVISORY_BOARD_TOKENS);
        transferInternal(this, slognConfig.opensourceFundManager, slognConfig.OPENSOURCE_TOKENS);
        transferInternal(this, slognConfig.reserveFundManager, slognConfig.RESERVE_TOKENS);
        transferInternal(this, slognConfig.bountyFundManager, slognConfig.BOUNTY_TOKENS);
    }

    function buyFor(address _user, uint256 ethers, uint time) internal returns (bool success) {
        require(ethers > 0);
        uint8 icoStep = getIcoStep(time);
        require(icoStep == 1 || icoStep == 2);
        if (icoStep == 1 && (escrowConfig.totalSoldTokens + ethers) > 5000 ether) {
            revert();
        }
        uint256 slognAmount = ethers;
        uint256 bonus = calculateBonus(icoStep, escrowConfig.totalSoldTokens, slognAmount);
        require(balanceOf[this] >= slognAmount + bonus);
        if (bonus > 0) {
            BonusEarned(_user, bonus);
        }
        transferInternal(this, _user, slognAmount + bonus);
        escrowConfig.totalSoldTokens += slognAmount;
        if (icoStep == 1) {
            preIcoEthers[_user] += ethers;
        }
        if (icoStep == 2) {
            icoEthers[_user] += ethers;
        }
        return true;
    }

    function buy() public payable {
        buyFor(msg.sender, msg.value, block.timestamp);
    }

    function transferEther(address to, uint256 value) public returns (bool success) {
        if (msg.sender != slognConfig.ethFundManager) {
            return false;
        }
        if (escrowConfig.totalSoldTokens < escrowConfig.MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }
        if (this.balance < value) {
            return false;
        }
        to.transfer(value);
        return true;
    }

    function transferTokens(address to, uint256 value) public returns (bool success) {
        if (!escrowConfig.isTransactionsAllowed) {
            if (msg.sender != slognConfig.bountyFundManager) {
                return false;
            }
        }
        return transferInternal(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (!escrowConfig.isTransactionsAllowed) {
            if (from != slognConfig.bountyFundManager) {
                return false;
            }
        }
        return transferFromInternal(from, to, value);
    }

    function refund() public returns (bool) {
        return refundInternal(block.timestamp);
    }

    function icoFinish() public returns (bool) {
        return icoFinishInternal(block.timestamp);
    }

    function setPreIcoDates(uint256 since, uint256 till) public onlyOwner {
        escrowConfig.PRE_ICO_SINCE = since;
        escrowConfig.PRE_ICO_TILL = till;
    }

    function setIcoDates(uint256 since, uint256 till) public onlyOwner {
        escrowConfig.ICO_SINCE = since;
        escrowConfig.ICO_TILL = till;
    }

    function setTransactionsAllowed(bool enabled) public onlyOwner {
        escrowConfig.isTransactionsAllowed = enabled;
    }

    function() public payable {
        revert();
    }
}
```