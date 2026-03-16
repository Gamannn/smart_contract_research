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

contract OnUpToken {
    string public constant name = "OnUp TOKEN";
    string public constant symbol = "OnUp";

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    function balanceOf(address owner) public constant returns (uint256) {
        return balanceOf[owner];
    }

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowance[owner][spender];
    }
}

contract OnUpAffiliate is OnUpToken {
    using SafeMath for uint256;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    mapping(address => address) public referrer;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public totalReferralAmount;

    struct ContractData {
        address owner;
        address admin;
        address treasury;
        address tokenAddress;
        address level1;
        address level2;
        address level3;
        address level4;
        address level5;
        uint256 totalSupply;
        uint256 tokenPrice;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalRaised;
    }

    ContractData public contractData = ContractData(
        0x516e0deBB3dB8C2c087786CcF7653fa0991784b3,
        0x28fF20D2d413A346F123198385CCf16E15295351,
        0xaB85Cb1087ce716E11dC37c69EaaBc09d674575d,
        address(0),
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0,
        700000000,
        6,
        "OnUp",
        "OnUp TOKEN",
        0
    );

    constructor() public payable {
        contractData.owner = msg.sender;
        referralCount[contractData.admin] = 6;
        referralCount[contractData.owner] = 6;
    }

    function() payable public {
        require(msg.value >= 0.01 ether);
        require(msg.value <= 30 ether);
        require(!isContract(msg.sender));

        if (msg.sender != contractData.treasury) {
            contractData.level1 = address(0);
            contractData.level2 = address(0);
            contractData.level3 = address(0);
            contractData.level4 = address(0);
            contractData.level5 = address(0);

            if (msg.sender != contractData.admin && msg.sender != contractData.owner) {
                processReferral();
            } else {
                processPurchase();
            }
        } else {
            contractData.totalRaised = contractData.totalRaised.add(msg.value.div(100).mul(90));
            contractData.tokenPrice = contractData.totalRaised.div(contractData.totalSupply);
        }
    }

    function processReferral() internal {
        if (msg.value >= 25 ether && referralCount[msg.sender] < 6) {
            referralCount[msg.sender] = 6;
        }
        if (msg.value >= 20 ether && referralCount[msg.sender] < 5) {
            referralCount[msg.sender] = 5;
        }
        if (msg.value >= 15 ether && referralCount[msg.sender] < 4) {
            referralCount[msg.sender] = 4;
        }
        if (msg.value >= 10 ether && referralCount[msg.sender] < 3) {
            referralCount[msg.sender] = 3;
        }
        if (msg.value >= 5 ether && referralCount[msg.sender] < 2) {
            referralCount[msg.sender] = 2;
        }
        if (msg.value >= 0.1 ether && referralCount[msg.sender] < 1) {
            referralCount[msg.sender] = 1;
        }
        if (totalReferralAmount[msg.sender] >= 250 ether && referralCount[msg.sender] < 6) {
            referralCount[msg.sender] = 6;
        }
        if (totalReferralAmount[msg.sender] >= 200 ether && referralCount[msg.sender] < 5) {
            referralCount[msg.sender] = 5;
        }
        if (totalReferralAmount[msg.sender] >= 150 ether && referralCount[msg.sender] < 4) {
            referralCount[msg.sender] = 4;
        }
        if (totalReferralAmount[msg.sender] >= 100 ether && referralCount[msg.sender] < 3) {
            referralCount[msg.sender] = 3;
        }
        if (totalReferralAmount[msg.sender] >= 50 ether && referralCount[msg.sender] < 2) {
            referralCount[msg.sender] = 2;
        }

        contractData.level1 = referrer[msg.sender];
        if (contractData.level1 == address(0)) {
            contractData.level1 = bytesToAddress(msg.data);
            require(!isContract(contractData.level1));
            require(balanceOf[contractData.level1] > 0);
            require(contractData.level1 != contractData.owner);
            require(contractData.level1 != contractData.treasury);
            referrer[msg.sender] = contractData.level1;
        }
        processPurchase();
    }

    function processPurchase() internal {
        uint256 tokens = msg.value.div(contractData.tokenPrice.mul(100).div(70));
        require(tokens > 0);
        require(balanceOf[msg.sender].add(tokens) > balanceOf[msg.sender]);

        uint256 referralBonus = msg.value.div(100);
        uint256 level1Bonus = referralBonus.mul(10);
        uint256 level2Bonus = 0;
        uint256 level3Bonus = 0;
        uint256 level4Bonus = 0;
        uint256 level5Bonus = 0;
        uint256 level6Bonus = 0;
        uint256 totalBonus = 0;

        if (msg.sender != contractData.admin && msg.sender != contractData.owner && msg.sender != contractData.owner) {
            if (contractData.level1 != address(0)) {
                totalReferralAmount[contractData.level1] = totalReferralAmount[contractData.level1].add(msg.value);
                if (referralCount[contractData.level1] > 1) {
                    level1Bonus = referralBonus.mul(2);
                    level2Bonus = referralBonus.mul(2);
                    totalBonus = totalBonus.add(2);
                } else if (referralCount[contractData.level1] > 0) {
                    level1Bonus = referralBonus;
                    level2Bonus = referralBonus;
                    totalBonus = totalBonus.add(1);
                }
            }
            if (contractData.level2 != address(0)) {
                if (referralCount[contractData.level2] > 2) {
                    level1Bonus = referralBonus.mul(2);
                    level3Bonus = referralBonus.mul(2);
                    totalBonus = totalBonus.add(2);
                } else if (referralCount[contractData.level2] > 0) {
                    level1Bonus = referralBonus;
                    level3Bonus = referralBonus;
                    totalBonus = totalBonus.add(1);
                }
            }
            if (contractData.level3 != address(0)) {
                if (referralCount[contractData.level3] > 3) {
                    level1Bonus = referralBonus.mul(2);
                    level4Bonus = referralBonus.mul(2);
                    totalBonus = totalBonus.add(2);
                } else if (referralCount[contractData.level3] > 0) {
                    level1Bonus = referralBonus;
                    level4Bonus = referralBonus;
                    totalBonus = totalBonus.add(1);
                }
            }
            if (contractData.level4 != address(0)) {
                if (referralCount[contractData.level4] > 4) {
                    level1Bonus = referralBonus.mul(2);
                    level5Bonus = referralBonus.mul(2);
                    totalBonus = totalBonus.add(2);
                } else if (referralCount[contractData.level4] > 0) {
                    level1Bonus = referralBonus;
                    level5Bonus = referralBonus;
                    totalBonus = totalBonus.add(1);
                }
            }
            if (contractData.level5 != address(0)) {
                if (referralCount[contractData.level5] > 5) {
                    level1Bonus = referralBonus.mul(2);
                    level6Bonus = referralBonus.mul(2);
                    totalBonus = totalBonus.add(2);
                } else if (referralCount[contractData.level5] > 0) {
                    level1Bonus = referralBonus;
                    level6Bonus = referralBonus;
                    totalBonus = totalBonus.add(1);
                }
            }
        }

        if (level1Bonus > 0) {
            uint256 level1Tokens = level1Bonus.div(contractData.tokenPrice.mul(100).div(70));
            require(level1Tokens > 0);
            uint256 level1Amount = level1Bonus.div(100);
            balanceOf[contractData.owner] = balanceOf[contractData.owner].add(level1Tokens);
            emit Transfer(this, contractData.owner, level1Tokens);
        }

        contractData.totalRaised = contractData.totalRaised.add(referralBonus.add(level1Amount).mul(85 - totalBonus));
        contractData.totalSupply = contractData.totalSupply.add(tokens.add(level1Tokens));
        contractData.tokenPrice = contractData.totalRaised.div(contractData.totalSupply);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        emit Transfer(this, msg.sender, tokens);

        tokens = 0;
        level1Tokens = 0;

        contractData.owner.transfer(referralBonus.mul(5));
        contractData.admin.transfer(referralBonus.mul(5));

        if (level2Bonus > 0) {
            contractData.level1.transfer(level2Bonus);
        }
        if (level3Bonus > 0) {
            contractData.level2.transfer(level3Bonus);
        }
        if (level4Bonus > 0) {
            contractData.level3.transfer(level4Bonus);
        }
        if (level5Bonus > 0) {
            contractData.level4.transfer(level5Bonus);
        }
        if (level6Bonus > 0) {
            contractData.level5.transfer(level6Bonus);
        }
    }

    function transfer(address to, uint256 value) public onlyPayloadSize(2 * 32) returns (bool) {
        require(balanceOf[msg.sender] >= value);

        if (to != address(this)) {
            if (msg.sender == contractData.owner) {
                require(value < 10000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            emit Transfer(msg.sender, to, value);
        } else {
            require(msg.sender != contractData.owner);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            uint256 etherValue = value.mul(contractData.tokenPrice);
            require(address(this).balance >= etherValue);

            if (contractData.totalSupply > value) {
                uint256 etherBalance = (address(this).balance.sub(contractData.totalRaised)).div(contractData.totalSupply);
                contractData.totalRaised = contractData.totalRaised.sub(etherValue);
                contractData.totalSupply = contractData.totalSupply.sub(value);
                contractData.totalRaised = contractData.totalRaised.add(etherBalance.mul(value));
                contractData.tokenPrice = contractData.totalRaised.div(contractData.totalSupply);
                emit Transfer(msg.sender, to, value);
            }

            if (contractData.totalSupply == value) {
                contractData.tokenPrice = address(this).balance.div(contractData.totalSupply);
                contractData.tokenPrice = contractData.tokenPrice.mul(101).div(100);
                contractData.totalSupply = 0;
                contractData.totalRaised = 0;
                emit Transfer(msg.sender, to, value);
                contractData.owner.transfer(address(this).balance.sub(etherValue));
            }

            msg.sender.transfer(etherValue);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public onlyPayloadSize(3 * 32) returns (bool) {
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);

        if (to != address(this)) {
            if (msg.sender == contractData.owner) {
                require(value < 10000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            balanceOf[from] = balanceOf[from].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
        } else {
            require(from != contractData.owner);
            balanceOf[from] = balanceOf[from].sub(value);
            uint256 etherValue = value.mul(contractData.tokenPrice);
            require(address(this).balance >= etherValue);

            if (contractData.totalSupply > value) {
                uint256 etherBalance = (address(this).balance.sub(contractData.totalRaised)).div(contractData.totalSupply);
                contractData.totalRaised = contractData.totalRaised.sub(etherValue);
                contractData.totalSupply = contractData.totalSupply.sub(value);
                contractData.totalRaised = contractData.totalRaised.add(etherBalance.mul(value));
                contractData.tokenPrice = contractData.totalRaised.div(contractData.totalSupply);
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            }

            if (contractData.totalSupply == value) {
                contractData.tokenPrice = address(this).balance.div(contractData.totalSupply);
                contractData.tokenPrice = contractData.tokenPrice.mul(101).div(100);
                contractData.totalSupply = 0;
                contractData.totalRaised = 0;
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
                contractData.owner.transfer(address(this).balance.sub(etherValue));
            }

            from.transfer(etherValue);
        }
        return true;
    }

    function bytesToAddress(bytes data) internal pure returns (address addr) {
        assembly {
            addr := mload(add(data, 0x14))
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
}
```