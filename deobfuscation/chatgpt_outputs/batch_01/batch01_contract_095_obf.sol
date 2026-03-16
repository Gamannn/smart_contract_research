```solidity
pragma solidity ^0.4.18;

contract Owned {
    address public owner;
    address public server;

    function Owned() public {
        owner = msg.sender;
        server = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeServer(address newServer) public onlyOwner {
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
    function Utils() public {}

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
}

contract Crowdsale is Owned, Utils {
    mapping(address => uint256) public balances;
    event Transfer(address indexed from, address indexed to, uint256 value);

    struct CrowdsaleData {
        bool transfersEnabled;
        uint256 totalSupply;
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

    CrowdsaleData public crowdsaleData;

    function GraphenePowerCrowdsale() public {
        balances[this] = 500000000;
        crowdsaleData.preSaleAddress = 0xC07850969A0EC345A84289f9C5bb5F979f27110f;
        crowdsaleData.icoAddress = 0x1C21Cf57BF4e2dd28883eE68C03a9725056D29F1;
        crowdsaleData.advisersConsultantsAddress = 0xe8B6dA1B801b7F57e3061C1c53a011b31C9315C7;
        crowdsaleData.bountyAddress = 0xD53E82Aea770feED8e57433D3D61674caEC1D1Be;
        crowdsaleData.founderAddress = 0xDA0D3Dad39165EA2d7386f18F96664Ee2e9FD8db;
    }

    function startIco() internal onlyOwner {
        crowdsaleData.icoStart = now;
    }

    function isIcoClosed() public view returns (bool closed) {
        return ((crowdsaleData.icoStart + (35 * 24 * 60 * 60)) >= now);
    }

    function isPreSaleClosed() public view returns (bool closed) {
        return (crowdsaleData.preSaleEnd >= now);
    }

    function getBountyTokens() public onlyOwner {
        require(crowdsaleData.bountyTokens > 0);
        payment(crowdsaleData.bountyAddress, crowdsaleData.bountyTokens);
        crowdsaleData.bountyTokens = 0;
    }

    function getFoundersTokens() public onlyOwner {
        require(crowdsaleData.founderTokens > 0);
        payment(crowdsaleData.founderAddress, crowdsaleData.founderTokens);
        crowdsaleData.founderTokens = 0;
    }

    function getAdvisersConsultantsTokens() public onlyOwner {
        require(crowdsaleData.advisersConsultantTokens > 0);
        payment(crowdsaleData.advisersConsultantsAddress, crowdsaleData.advisersConsultantTokens);
        crowdsaleData.advisersConsultantTokens = 0;
    }

    function payment(address to, uint256 tokens) internal {
        if (balances[this] > tokens) {
            balances[msg.sender] += tokens;
            balances[this] -= tokens;
            Transfer(this, to, tokens);
        }
    }

    function() public payable {
        require(msg.value > 0);
        if (!isPreSaleClosed()) {
            uint256 tokensPreSale = crowdsaleData.preSaleTotalTokens * msg.value / 1 ether;
            require(crowdsaleData.preSaleTotalTokens >= tokensPreSale);
            payment(msg.sender, tokensPreSale);
        } else if (!isIcoClosed()) {
            if ((crowdsaleData.icoStart + (7 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek1 = 4000 * msg.value / 1 ether;
                require(crowdsaleData.icoSaleTotalTokens >= tokensWeek1);
                payment(msg.sender, tokensWeek1);
                crowdsaleData.icoSaleTotalTokens -= tokensWeek1;
            } else if ((crowdsaleData.icoStart + (14 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek2 = 3750 * msg.value / 1 ether;
                require(crowdsaleData.icoSaleTotalTokens >= tokensWeek2);
                payment(msg.sender, tokensWeek2);
                crowdsaleData.icoSaleTotalTokens -= tokensWeek2;
            } else if ((crowdsaleData.icoStart + (21 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek3 = 3500 * msg.value / 1 ether;
                require(crowdsaleData.icoSaleTotalTokens >= tokensWeek3);
                payment(msg.sender, tokensWeek3);
                crowdsaleData.icoSaleTotalTokens -= tokensWeek3;
            } else if ((crowdsaleData.icoStart + (28 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek4 = 3250 * msg.value / 1 ether;
                require(crowdsaleData.icoSaleTotalTokens >= tokensWeek4);
                payment(msg.sender, tokensWeek4);
                crowdsaleData.icoSaleTotalTokens -= tokensWeek4;
            } else if ((crowdsaleData.icoStart + (35 * 24 * 60 * 60)) >= now) {
                uint256 tokensWeek5 = 3000 * msg.value / 1 ether;
                require(crowdsaleData.icoSaleTotalTokens >= tokensWeek5);
                payment(msg.sender, tokensWeek5);
                crowdsaleData.icoSaleTotalTokens -= tokensWeek5;
            }
        }
    }
}

contract GraphenePowerToken is Crowdsale {
    string public standard = 'Token 0.1';
    string public name = 'Graphene Power';
    string public symbol = 'GRP';

    mapping(address => uint256) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return crowdsaleData.totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if (crowdsaleData.transfersEnabled) {
            require(balances[msg.sender] >= value);
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function enableTransfers() public onlyOwner {
        require(!crowdsaleData.transfersEnabled);
        crowdsaleData.transfersEnabled = true;
    }
}
```