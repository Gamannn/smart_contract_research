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

contract OnUpToken {
    string public constant name = "OnUp TOKEN";
    string public constant symbol = "OnUp";
    uint256 public totalSupply = 700000000;
    uint256 public circulatingSupply;

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

contract OnUpTokenAffiliate is OnUpToken {
    using SafeMath for uint256;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    mapping(address => address) public referrer;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public referralBalance;

    struct AffiliateData {
        address affiliate;
        address admin;
        address owner;
        address referrer;
        address level5;
        address level4;
        address level3;
        address level2;
        address level1;
        uint256 totalReferralBalance;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        uint256 circulatingSupply;
    }

    AffiliateData public affiliateData = AffiliateData(
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

    constructor() payable public {
        affiliateData.owner = msg.sender;
        referralCount[affiliateData.admin] = 6;
        referralCount[affiliateData.owner] = 6;
    }

    function() payable public {
        require(!isContract(msg.sender));
        require(msg.value >= 0.01 ether);
        require(msg.value <= 30 ether);

        if (msg.sender != affiliateData.owner) {
            affiliateData.referrer = address(0);
            affiliateData.level1 = address(0);
            affiliateData.level2 = address(0);
            affiliateData.level3 = address(0);
            affiliateData.level4 = address(0);

            if (msg.sender != affiliateData.admin && msg.sender != affiliateData.owner) {
                processReferral();
            } else {
                processAdmin();
            }
        } else {
            affiliateData.circulatingSupply = affiliateData.circulatingSupply.add(msg.value.div(100).mul(90));
            affiliateData.totalSupply = affiliateData.circulatingSupply.div(affiliateData.circulatingSupply);
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

        if (referralBalance[msg.sender] >= 250 ether && referralCount[msg.sender] < 6) {
            referralCount[msg.sender] = 6;
        }
        if (referralBalance[msg.sender] >= 200 ether && referralCount[msg.sender] < 5) {
            referralCount[msg.sender] = 5;
        }
        if (referralBalance[msg.sender] >= 150 ether && referralCount[msg.sender] < 4) {
            referralCount[msg.sender] = 4;
        }
        if (referralBalance[msg.sender] >= 100 ether && referralCount[msg.sender] < 3) {
            referralCount[msg.sender] = 3;
        }
        if (referralBalance[msg.sender] >= 50 ether && referralCount[msg.sender] < 2) {
            referralCount[msg.sender] = 2;
        }

        affiliateData.referrer = referrer[msg.sender];
        if (affiliateData.referrer == address(0)) {
            affiliateData.referrer = bytesToAddress(msg.data);
            require(!isContract(affiliateData.referrer));
            require(balanceOf[affiliateData.referrer] > 0);
            require(affiliateData.referrer != affiliateData.affiliate);
            require(affiliateData.referrer != affiliateData.owner);
            referrer[msg.sender] = affiliateData.referrer;
        }
        processAdmin();
    }

    function processAdmin() internal {
        uint256 tokens = msg.value.div((affiliateData.totalSupply.mul(100)).div(70));
        require(tokens > 0);
        require(balanceOf[msg.sender].add(tokens) > balanceOf[msg.sender]);

        uint256 referralTokens = msg.value.div(100);
        uint256 level1Tokens = referralTokens.mul(10);
        uint256 level2Tokens = 0;
        uint256 level3Tokens = 0;
        uint256 level4Tokens = 0;
        uint256 level5Tokens = 0;
        uint256 level6Tokens = 0;
        uint256 totalReferralTokens = 10;
        uint256 remainingTokens = 0;

        if (msg.sender != affiliateData.admin && msg.sender != affiliateData.owner && msg.sender != affiliateData.affiliate) {
            if (affiliateData.referrer != address(0)) {
                referralBalance[affiliateData.referrer] = referralBalance[affiliateData.referrer].add(msg.value);
                if (referralBalance[affiliateData.referrer] >= 250 ether && referralCount[affiliateData.referrer] < 6) {
                    referralCount[affiliateData.referrer] = 6;
                }
                if (referralBalance[affiliateData.referrer] >= 200 ether && referralCount[affiliateData.referrer] < 5) {
                    referralCount[affiliateData.referrer] = 5;
                }
                if (referralBalance[affiliateData.referrer] >= 150 ether && referralCount[affiliateData.referrer] < 4) {
                    referralCount[affiliateData.referrer] = 4;
                }
                if (referralBalance[affiliateData.referrer] >= 100 ether && referralCount[affiliateData.referrer] < 3) {
                    referralCount[affiliateData.referrer] = 3;
                }
                if (referralBalance[affiliateData.referrer] >= 50 ether && referralCount[affiliateData.referrer] < 2) {
                    referralCount[affiliateData.referrer] = 2;
                }
                if (referrer[affiliateData.referrer] != address(0)) {
                    affiliateData.level1 = referrer[affiliateData.referrer];
                }
                if (referrer[affiliateData.level1] != address(0)) {
                    affiliateData.level2 = referrer[affiliateData.level1];
                }
                if (referrer[affiliateData.level2] != address(0)) {
                    affiliateData.level3 = referrer[affiliateData.level2];
                }
                if (referrer[affiliateData.level3] != address(0)) {
                    affiliateData.level4 = referrer[affiliateData.level3];
                }
                if (referralCount[affiliateData.referrer] > 1) {
                    level1Tokens = level1Tokens.sub(referralTokens);
                    level2Tokens = referralTokens.mul(2);
                    totalReferralTokens = totalReferralTokens.sub(2);
                } else if (referralCount[affiliateData.referrer] > 0) {
                    level2Tokens = referralTokens;
                    totalReferralTokens = totalReferralTokens.sub(1);
                }
            }
            if (affiliateData.level1 != address(0)) {
                if (referralCount[affiliateData.level1] > 2) {
                    level1Tokens = level1Tokens.sub(referralTokens.mul(2));
                    level3Tokens = referralTokens.mul(2);
                    totalReferralTokens = totalReferralTokens.sub(2);
                } else if (referralCount[affiliateData.level1] > 0) {
                    level3Tokens = referralTokens;
                    totalReferralTokens = totalReferralTokens.sub(1);
                }
            }
            if (affiliateData.level2 != address(0)) {
                if (referralCount[affiliateData.level2] > 3) {
                    level1Tokens = level1Tokens.sub(referralTokens.mul(2));
                    level4Tokens = referralTokens.mul(2);
                    totalReferralTokens = totalReferralTokens.sub(2);
                } else if (referralCount[affiliateData.level2] > 0) {
                    level4Tokens = referralTokens;
                    totalReferralTokens = totalReferralTokens.sub(1);
                }
            }
            if (affiliateData.level3 != address(0)) {
                if (referralCount[affiliateData.level3] > 4) {
                    level1Tokens = level1Tokens.sub(referralTokens.mul(2));
                    level5Tokens = referralTokens.mul(2);
                    totalReferralTokens = totalReferralTokens.sub(2);
                } else if (referralCount[affiliateData.level3] > 0) {
                    level5Tokens = referralTokens;
                    totalReferralTokens = totalReferralTokens.sub(1);
                }
            }
            if (affiliateData.level4 != address(0)) {
                if (referralCount[affiliateData.level4] > 5) {
                    level1Tokens = level1Tokens.sub(referralTokens.mul(2));
                    level6Tokens = referralTokens.mul(2);
                    totalReferralTokens = totalReferralTokens.sub(2);
                } else if (referralCount[affiliateData.level4] > 0) {
                    level6Tokens = referralTokens;
                    totalReferralTokens = totalReferralTokens.sub(1);
                }
            }
        }

        if (level1Tokens > 0) {
            remainingTokens = level1Tokens.div((affiliateData.totalSupply.mul(100)).div(70));
            require(remainingTokens > 0);
            level1Tokens = level1Tokens.div(100);
            balanceOf[affiliateData.affiliate] = balanceOf[affiliateData.affiliate].add(remainingTokens);
            emit Transfer(this, affiliateData.affiliate, remainingTokens);
        }

        affiliateData.circulatingSupply = affiliateData.circulatingSupply.add((referralTokens + level1Tokens).mul(85 - totalReferralTokens));
        affiliateData.totalSupply = affiliateData.circulatingSupply.div(affiliateData.circulatingSupply);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        emit Transfer(this, msg.sender, tokens);

        tokens = 0;
        remainingTokens = 0;

        affiliateData.owner.transfer(referralTokens.mul(5));
        affiliateData.admin.transfer(referralTokens.mul(5));

        if (level2Tokens > 0) {
            affiliateData.referrer.transfer(level2Tokens);
        }
        if (level3Tokens > 0) {
            affiliateData.level1.transfer(level3Tokens);
        }
        if (level4Tokens > 0) {
            affiliateData.level2.transfer(level4Tokens);
        }
        if (level5Tokens > 0) {
            affiliateData.level3.transfer(level5Tokens);
        }
        if (level6Tokens > 0) {
            affiliateData.level4.transfer(level6Tokens);
        }
    }

    function transfer(address to, uint256 value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        if (to != address(this)) {
            if (msg.sender == affiliateData.affiliate) {
                require(value < 20000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            emit Transfer(msg.sender, to, value);
        } else {
            require(msg.sender != affiliateData.affiliate);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            uint256 etherValue = value.mul(affiliateData.totalSupply);
            require(address(this).balance >= etherValue);

            if (affiliateData.circulatingSupply > value) {
                uint256 etherBalance = (address(this).balance.sub(affiliateData.circulatingSupply)).div(affiliateData.circulatingSupply);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.sub(etherValue);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.sub(value);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.add(etherBalance.mul(value));
                affiliateData.totalSupply = affiliateData.circulatingSupply.div(affiliateData.circulatingSupply);
                emit Transfer(msg.sender, to, value);
            }

            if (affiliateData.circulatingSupply == value) {
                affiliateData.totalSupply = address(this).balance.div(affiliateData.circulatingSupply);
                affiliateData.totalSupply = (affiliateData.totalSupply.mul(101)).div(100);
                affiliateData.circulatingSupply = 0;
                affiliateData.circulatingSupply = 0;
                emit Transfer(msg.sender, to, value);
                affiliateData.owner.transfer(address(this).balance.sub(etherValue));
            }

            msg.sender.transfer(etherValue);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);

        if (to != address(this)) {
            if (msg.sender == affiliateData.affiliate) {
                require(value < 20000001);
            }
            require(balanceOf[to].add(value) >= balanceOf[to]);
            balanceOf[from] = balanceOf[from].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
        } else {
            require(from != affiliateData.affiliate);
            balanceOf[from] = balanceOf[from].sub(value);
            uint256 etherValue = value.mul(affiliateData.totalSupply);
            require(address(this).balance >= etherValue);

            if (affiliateData.circulatingSupply > value) {
                uint256 etherBalance = (address(this).balance.sub(affiliateData.circulatingSupply)).div(affiliateData.circulatingSupply);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.sub(etherValue);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.sub(value);
                affiliateData.circulatingSupply = affiliateData.circulatingSupply.add(etherBalance.mul(value));
                affiliateData.totalSupply = affiliateData.circulatingSupply.div(affiliateData.circulatingSupply);
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            }

            if (affiliateData.circulatingSupply == value) {
                affiliateData.totalSupply = address(this).balance.div(affiliateData.circulatingSupply);
                affiliateData.totalSupply = (affiliateData.totalSupply.mul(101)).div(100);
                affiliateData.circulatingSupply = 0;
                affiliateData.circulatingSupply = 0;
                emit Transfer(from, to, value);
                allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
                affiliateData.owner.transfer(address(this).balance.sub(etherValue));
            }

            from.transfer(etherValue);
        }

        return true;
    }

    function bytesToAddress(bytes memory b) internal pure returns (address addr) {
        assembly {
            addr := mload(add(b, 20))
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}