pragma solidity ^0.4.17;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 _allowance = allowed[from][msg.sender];

        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract VuePayTokenSale is StandardToken, Ownable {
    using SafeMath for uint256;

    event CreatedVUP(address indexed creator, uint256 amountOfVUP);
    event VUPRefundedForWei(address indexed refunder, uint256 amountOfWei);

    string public constant name = "VuePay Token";
    string public constant symbol = "VUP";
    string public version = "1.0";

    mapping (address => uint256) public ETHContributed;

    struct SaleConfig {
        uint256 VUP_PER_ETH_ICO_TIER3_RATE;
        uint256 VUP_PER_ETH_ICO_TIER2_RATE;
        uint256 VUP_PER_ETH_PRE_SALE_RATE;
        uint256 VUP_PER_ETH_BASE_RATE;
        uint256 UDF_PORTION;
        uint256 CO_FOUNDER_PORTION;
        uint256 DEV_TEAM_PORTION;
        uint256 CORE_TEAM_PORTION;
        uint256 ADVISORY_TEAM_PORTION;
        uint256 PRESALE_ICO_PORTION;
        uint256 VUP_TOKEN_SUPPLY_TIER4;
        uint256 VUP_TOKEN_SUPPLY_TIER3;
        uint256 VUP_TOKEN_SUPPLY_TIER2;
        uint256 VUP_TOKEN_SUPPLY_TIER1;
        uint256 INITIAL_VUP_TOKEN_SUPPLY;
        uint256 curTokenRate;
        uint256 advisoryTeamShare;
        uint256 cofounderShare;
        uint256 coreTeamShare;
        uint256 unsoldUnlockedAt;
        uint256 coreTeamUnlockedAt;
        uint256 coldStorageYears;
        uint256 icoEndBlock;
        uint256 preSaleEndBlock;
        uint256 preSaleStartBlock;
        uint256 totalETHRaised;
        bool allowRefund;
        bool preSaleEnded;
        bool minCapReached;
        bool saleHasEnded;
        uint256 totalVUP;
        address unsoldVUPDestination;
        address cofounderVUPDestination;
        address udfVUPDestination;
        address advisoryVUPDestination;
        address coreVUPDestination;
        address devVUPDestination;
        address vuePayETHDestination;
        address executor;
        uint256 decimals;
        uint256 remainingSupply;
    }

    SaleConfig public saleConfig;

    function VuePayTokenSale() public payable {
        saleConfig = SaleConfig({
            VUP_PER_ETH_ICO_TIER3_RATE: 2250,
            VUP_PER_ETH_ICO_TIER2_RATE: 2500,
            VUP_PER_ETH_PRE_SALE_RATE: 3000,
            VUP_PER_ETH_BASE_RATE: 2000,
            UDF_PORTION: 100000000e18,
            CO_FOUNDER_PORTION: 350000000e18,
            DEV_TEAM_PORTION: 50000000e18,
            CORE_TEAM_PORTION: 50000000e18,
            ADVISORY_TEAM_PORTION: 50000000e18,
            PRESALE_ICO_PORTION: 400000000e18,
            VUP_TOKEN_SUPPLY_TIER4: 400000000e18,
            VUP_TOKEN_SUPPLY_TIER3: 380000000e18,
            VUP_TOKEN_SUPPLY_TIER2: 270000000e18,
            VUP_TOKEN_SUPPLY_TIER1: 150000000e18,
            INITIAL_VUP_TOKEN_SUPPLY: 1000000000e18,
            curTokenRate: 2000,
            advisoryTeamShare: 0,
            cofounderShare: 0,
            coreTeamShare: 0,
            unsoldUnlockedAt: 0,
            coreTeamUnlockedAt: 0,
            coldStorageYears: 10 years,
            icoEndBlock: 0,
            preSaleEndBlock: 0,
            preSaleStartBlock: 4340582,
            totalETHRaised: 0,
            allowRefund: false,
            preSaleEnded: false,
            minCapReached: false,
            saleHasEnded: false,
            totalVUP: 0,
            unsoldVUPDestination: 0x5076084a3377ecDF8AD5cD0f26A21bA848DdF435,
            cofounderVUPDestination: 0x863B2217E80e6C6192f63D3716c0cC7711Fad5b4,
            udfVUPDestination: 0xf4307C073451b80A0BaD1E099fD2B7f0fe38b7e9,
            advisoryVUPDestination: 0x991ABE74a1AC3d903dA479Ca9fede3d0954d430B,
            coreVUPDestination: 0x22d310194b5ac5086bDacb2b0f36D8f0a5971b23,
            devVUPDestination: 0x31403fA55aEa2065bBDd2778bFEd966014ab0081,
            vuePayETHDestination: 0x8B8698DEe100FC5F561848D0E57E94502Bd9318b,
            executor: msg.sender,
            decimals: 18,
            remainingSupply: 1000000000e18
        });

        saleConfig.preSaleEndBlock = saleConfig.preSaleStartBlock + 37800;
        saleConfig.icoEndBlock = saleConfig.preSaleEndBlock + 81000;
    }

    function () payable public {
        require(msg.value >= .05 ether);
        require(!saleConfig.saleHasEnded);
        require(block.number >= saleConfig.preSaleStartBlock);
        require(block.number < saleConfig.icoEndBlock);

        if (block.number > saleConfig.preSaleEndBlock) {
            saleConfig.preSaleEnded = true;
        }

        require(msg.value != 0);

        uint256 newEtherBalance = saleConfig.totalETHRaised.add(msg.value);
        getCurrentVUPRate();
        uint256 amountOfVUP = msg.value.mul(saleConfig.curTokenRate);

        saleConfig.totalVUP = saleConfig.totalVUP.add(amountOfVUP);
        require(saleConfig.totalVUP <= saleConfig.PRESALE_ICO_PORTION);

        uint256 totalSupplySafe = saleConfig.remainingSupply.sub(amountOfVUP);
        uint256 balanceSafe = balances[msg.sender].add(amountOfVUP);
        uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

        saleConfig.remainingSupply = totalSupplySafe;
        balances[msg.sender] = balanceSafe;
        saleConfig.totalETHRaised = newEtherBalance;
        ETHContributed[msg.sender] = contributedSafe;

        CreatedVUP(msg.sender, amountOfVUP);
    }

    function getCurrentVUPRate() internal {
        saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_BASE_RATE;

        if ((saleConfig.totalVUP <= saleConfig.VUP_TOKEN_SUPPLY_TIER1) && (!saleConfig.preSaleEnded)) {
            saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_PRE_SALE_RATE;
        }

        if ((saleConfig.totalVUP <= saleConfig.VUP_TOKEN_SUPPLY_TIER1) && (saleConfig.preSaleEnded)) {
            saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_ICO_TIER2_RATE;
        }

        if (saleConfig.totalVUP > saleConfig.VUP_TOKEN_SUPPLY_TIER1) {
            saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_ICO_TIER2_RATE;
        }

        if (saleConfig.totalVUP > saleConfig.VUP_TOKEN_SUPPLY_TIER2) {
            saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_ICO_TIER3_RATE;
        }

        if (saleConfig.totalVUP > saleConfig.VUP_TOKEN_SUPPLY_TIER3) {
            saleConfig.curTokenRate = saleConfig.VUP_PER_ETH_BASE_RATE;
        }
    }

    function createCustomVUP(address clientVUPAddress, uint256 amount) public onlyOwner {
        require(clientVUPAddress != address(0x0));
        require(amount > 0);
        require(saleConfig.advisoryTeamShare >= amount);

        saleConfig.advisoryTeamShare = saleConfig.advisoryTeamShare.sub(amount);
        saleConfig.totalVUP = saleConfig.totalVUP.add(amount);

        uint256 balanceSafe = balances[clientVUPAddress].add(amount);
        balances[clientVUPAddress] = balanceSafe;

        CreatedVUP(clientVUPAddress, amount);
    }

    function endICO() public onlyOwner {
        require(!saleConfig.saleHasEnded);
        require(saleConfig.minCapReached);

        saleConfig.saleHasEnded = true;
        saleConfig.coreTeamShare = saleConfig.CORE_TEAM_PORTION;
        uint256 devTeamShare = saleConfig.DEV_TEAM_PORTION;
        saleConfig.cofounderShare = saleConfig.CO_FOUNDER_PORTION;
        uint256 udfShare = saleConfig.UDF_PORTION;

        balances[saleConfig.devVUPDestination] = devTeamShare;
        balances[saleConfig.advisoryVUPDestination] = saleConfig.advisoryTeamShare;
        balances[saleConfig.udfVUPDestination] = udfShare;

        uint nineMonths = 9 * 30 days;
        saleConfig.coreTeamUnlockedAt = now.add(nineMonths);

        uint lockTime = saleConfig.coldStorageYears;
        saleConfig.unsoldUnlockedAt = now.add(lockTime);

        CreatedVUP(saleConfig.devVUPDestination, devTeamShare);
        CreatedVUP(saleConfig.advisoryVUPDestination, saleConfig.advisoryTeamShare);
        CreatedVUP(saleConfig.udfVUPDestination, udfShare);
    }

    function unlock() public onlyOwner {
        require(saleConfig.saleHasEnded);
        require(now > saleConfig.coreTeamUnlockedAt || now > saleConfig.unsoldUnlockedAt);

        if (now > saleConfig.coreTeamUnlockedAt) {
            balances[saleConfig.coreVUPDestination] = saleConfig.coreTeamShare;
            CreatedVUP(saleConfig.coreVUPDestination, saleConfig.coreTeamShare);

            balances[saleConfig.cofounderVUPDestination] = saleConfig.cofounderShare;
            CreatedVUP(saleConfig.cofounderVUPDestination, saleConfig.cofounderShare);
        }

        if (now > saleConfig.unsoldUnlockedAt) {
            uint256 unsoldTokens = saleConfig.PRESALE_ICO_PORTION.sub(saleConfig.totalVUP);
            require(unsoldTokens > 0);

            balances[saleConfig.unsoldVUPDestination] = unsoldTokens;
            CreatedVUP(saleConfig.coreVUPDestination, unsoldTokens);
        }
    }

    function withdrawFunds() public onlyOwner {
        require(saleConfig.minCapReached);
        require(this.balance > 0);

        if (this.balance > 0) {
            saleConfig.vuePayETHDestination.transfer(this.balance);
        }
    }

    function triggerMinCap() public onlyOwner {
        saleConfig.minCapReached = true;
    }

    function triggerRefund() public onlyOwner {
        require(!saleConfig.saleHasEnded);
        require(!saleConfig.minCapReached);
        require(block.number > saleConfig.icoEndBlock);
        require(msg.sender == saleConfig.executor);

        saleConfig.allowRefund = true;
    }

    function claimRefund() external {
        require(saleConfig.allowRefund);
        require(ETHContributed[msg.sender] != 0);

        uint256 etherAmount = ETHContributed[msg.sender];
        ETHContributed[msg.sender] = 0;

        VUPRefundedForWei(msg.sender, etherAmount);
        msg.sender.transfer(etherAmount);
    }

    function changeVuePayETHDestinationAddress(address newAddress) public onlyOwner {
        saleConfig.vuePayETHDestination = newAddress;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(saleConfig.minCapReached);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(saleConfig.minCapReached);
        return super.transferFrom(from, to, value);
    }
}