pragma solidity ^0.4.18;

contract owned {
    address public owner;
    address public server;

    function owned() {
        owner = msg.sender;
        server = msg.sender;
    }

    function changeOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }

    function changeServer(address newServer) onlyOwner {
        server = newServer;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyServer {
        require(msg.sender == server);
        _;
    }
}

contract Utils {
    function Utils() {}

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
}

contract Crowdsale is owned, Utils {
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function GraphenePowerCrowdsale() {
        balanceOf[this] = 500000000;
        s2c.preSaleAddress = 0xC07850969A0EC345A84289f9C5bb5F979f27110f;
        s2c.icoAddress = 0x1C21Cf57BF4e2dd28883eE68C03a9725056D29F1;
        s2c.advisersConsultantsAddress = 0xe8B6dA1B801b7F57e3061C1c53a011b31C9315C7;
        s2c.bountyAddress = 0xD53E82Aea770feED8e57433D3D61674caEC1D1Be;
        s2c.founderAddress = 0xDA0D3Dad39165EA2d7386f18F96664Ee2e9FD8db;
    }

    function startIco() onlyOwner internal {
        s2c.icoStart = now;
    }

    function isIcoClosed() constant returns (bool closed) {
        return ((s2c.icoStart + (35 * 24 * 60 * 60)) >= now);
    }

    function isPreSaleClosed() constant returns (bool closed) {
        return (s2c.preSaleEnd >= now);
    }

    function getBountyTokens() onlyOwner {
        require(s2c.bountyTokens > 0);
        payment(s2c.bountyAddress, s2c.bountyTokens);
        s2c.bountyTokens = 0;
    }

    function getFoundersTokens() onlyOwner {
        require(s2c.founderTokens > 0);
        payment(s2c.founderAddress, s2c.founderTokens);
        s2c.founderTokens = 0;
    }

    function getAdvisersConsultantsTokens() onlyOwner {
        require(s2c.advisersConsultantTokens > 0);
        payment(s2c.advisersConsultantsAddress, s2c.advisersConsultantTokens);
        s2c.advisersConsultantTokens = 0;
    }

    function payment(address to, uint256 tokens) internal {
        if (balanceOf[this] > tokens) {
            balanceOf[msg.sender] += tokens;
            balanceOf[this] -= tokens;
            Transfer(this, to, tokens);
        }
    }

    function() payable {
        require(msg.value > 0);
        if (!isPreSaleClosed()) {
            uint256 tokensPreSale = s2c.preSaleTotalTokens * msg.value / 1000000000000000000;
            require(s2c.preSaleTotalTokens >= tokensPreSale);
            payment(msg.sender, tokensPreSale);
        } else if (!isIcoClosed()) {
            if ((s2c.icoStart + (7 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek1 = 4000 * msg.value / 1000000000000000000;
                require(s2c.icoSaleTotalTokens >= tokensWeek1);
                payment(msg.sender, tokensWeek1);
                s2c.icoSaleTotalTokens -= tokensWeek1;
            } else if ((s2c.icoStart + (14 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek2 = 3750 * msg.value / 1000000000000000000;
                require(s2c.icoSaleTotalTokens >= tokensWeek2);
                payment(msg.sender, tokensWeek2);
                s2c.icoSaleTotalTokens -= tokensWeek2;
            } else if ((s2c.icoStart + (21 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek3 = 3500 * msg.value / 1000000000000000000;
                require(s2c.icoSaleTotalTokens >= tokensWeek3);
                payment(msg.sender, tokensWeek3);
                s2c.icoSaleTotalTokens -= tokensWeek3;
            } else if ((s2c.icoStart + (28 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek4 = 3250 * msg.value / 1000000000000000000;
                require(s2c.icoSaleTotalTokens >= tokensWeek4);
                payment(msg.sender, tokensWeek4);
                s2c.icoSaleTotalTokens -= tokensWeek4;
            } else if ((s2c.icoStart + (35 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek5 = 3000 * msg.value / 1000000000000000000;
                require(s2c.icoSaleTotalTokens >= tokensWeek5);
                payment(msg.sender, tokensWeek5);
                s2c.icoSaleTotalTokens -= tokensWeek5;
            }
        }
    }
}

contract GraphenePowerToken is Crowdsale {
    string public standard = 'Token 0.1';
    string public name = 'Graphene Power';
    string public symbol = 'GRP';
    mapping (address => uint256) public allowance;
    event Transfer(address from, address to, uint256 value);

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = s2c._totalSupply;
    }

    function transfer(address to, uint256 tokens) returns (bool success) {
        if (s2c.transfersEnable) {
            require(balanceOf[msg.sender] >= tokens);
            balanceOf[msg.sender] -= tokens;
            balanceOf[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }

    function transfersEnabled() onlyOwner {
        require(!s2c.transfersEnable);
        s2c.transfersEnable = true;
    }

    struct scalar2Vector {
        bool transfersEnable;
        uint256 _totalSupply;
        uint8 decimals;
        address founderAddress;
        uint256 founderTokens;
        address bountyAddress;
        uint256 bountyTokens;
        address advisersConsultantsAddress;
        uint256 advisersConsultantTokens;
        address icoAddress;
        uint256 icoSaleTotalTokens;
        uint256 icoStart;
        address preSaleAddress;
        uint256 preSaleTokenCost;
        uint256 preSaleTotalTokens;
        uint256 preSaleEnd;
        uint256 preSaleStart;
        address server;
        address owner;
    }

    scalar2Vector s2c = scalar2Vector(
        false,
        500000000,
        18,
        address(0),
        40000000,
        0xD53E82Aea770feED8e57433D3D61674caEC1D1Be,
        15000000,
        address(0),
        15000000,
        address(0),
        400000000,
        0,
        address(0),
        6000,
        30000000,
        1515585600,
        1513771200,
        address(0),
        address(0)
    );
}