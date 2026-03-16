pragma solidity ^0.4.4;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token {
    function totalSupply() public constant returns (uint256 supply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);
}

contract StandardToken is Token, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        emit Burn(_from, _value);
        return true;
    }
}

contract CryptonCoin is StandardToken {
    struct ICOData {
        uint256 finalTokensIssueTime;
        uint256 icoEndTime;
        uint256 preIcoEndTime;
        bool tokensCreated;
        bool icoFinished;
        uint256 totalEthInWei;
        uint256 unitsOneEthCanBuy;
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 icoTotalSupply;
        uint256 icoSupply;
        uint256 preIcoTotalSupply;
        uint256 preIcoSupply;
        address contractAddress;
        address fundsWallet;
        string version;
        string symbol;
        uint8 decimals;
        string name;
    }

    ICOData public icoData;

    function CryptonCoin() public {
        icoData.fundsWallet = msg.sender;
        icoData.name = "CRYPTON";
        icoData.symbol = "CRN";
        icoData.decimals = 18;
        balances[icoData.fundsWallet] = 0;
        totalSupply = 0;
        icoData.preIcoTotalSupply = 14400000000000000000000000;
        icoData.icoTotalSupply = 36000000000000000000000000;
        icoData.maxSupply = 72000000000000000000000000;
        icoData.unitsOneEthCanBuy = 377;
        icoData.preIcoEndTime = 1524785992;
        icoData.icoEndTime = 1528587592;
        icoData.finalTokensIssueTime = 1577921992;
        icoData.contractAddress = address(this);
    }

    function() public payable {
        require(!icoData.icoFinished);
        require(block.timestamp < icoData.icoEndTime);
        require(msg.value != 0);
        icoData.totalEthInWei = icoData.totalEthInWei + msg.value;
        uint256 amount = 0;
        uint256 tokenPrice = icoData.unitsOneEthCanBuy;
        if (block.timestamp < icoData.preIcoEndTime) {
            require(msg.value * tokenPrice * 13 / 10 <= (icoData.preIcoTotalSupply - icoData.preIcoSupply));
            tokenPrice = safeMul(tokenPrice, 13);
            tokenPrice = safeDiv(tokenPrice, 10);
            amount = safeMul(msg.value, tokenPrice);
            icoData.preIcoSupply = safeAdd(icoData.preIcoSupply, amount);
            balances[msg.sender] = safeAdd(balances[msg.sender], amount);
            totalSupply = safeAdd(totalSupply, amount);
            emit Transfer(icoData.contractAddress, msg.sender, amount);
        } else {
            require(msg.value * tokenPrice <= (icoData.icoTotalSupply - icoData.icoSupply));
            amount = safeMul(msg.value, tokenPrice);
            icoData.icoSupply = safeAdd(icoData.icoSupply, amount);
            balances[msg.sender] = safeAdd(balances[msg.sender], amount);
            totalSupply = safeAdd(totalSupply, amount);
            emit Transfer(icoData.contractAddress, msg.sender, amount);
        }
    }

    function withdraw() public {
        require(msg.sender == icoData.fundsWallet);
        icoData.fundsWallet.transfer(icoData.contractAddress.balance);
    }

    function createTokensForCrypton() public returns (bool success) {
        require(icoData.icoFinished);
        require(!icoData.tokensCreated);
        if (block.timestamp > icoData.finalTokensIssueTime) {
            uint256 amount = safeAdd(icoData.preIcoSupply, icoData.icoSupply);
            amount = safeMul(amount, 3);
            amount = safeDiv(amount, 10);
            balances[icoData.fundsWallet] = safeAdd(balances[icoData.fundsWallet], amount);
            totalSupply = safeAdd(totalSupply, amount);
            emit Transfer(icoData.contractAddress, icoData.fundsWallet, amount);
            icoData.tokensCreated = true;
            return true;
        }
    }

    function stopIco() public returns (bool success) {
        if (block.timestamp > icoData.icoEndTime) {
            icoData.icoFinished = true;
            return true;
        }
    }

    function setTokenPrice(uint256 newPrice) public returns (bool success) {
        require(msg.sender == icoData.fundsWallet);
        require(newPrice < 1500);
        icoData.unitsOneEthCanBuy = newPrice;
        return true;
    }
}