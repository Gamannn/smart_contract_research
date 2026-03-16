pragma solidity ^0.4.18;

contract TokenContract {
    string public name;
    string public symbol;
    string public version = 'Token 0.1';
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    struct TokenData {
        uint256 lastBlock;
        uint256 sellPrice;
        uint256 buyPrice;
        uint256 totalSupply;
        uint8 decimals;
    }

    TokenData public tokenData = TokenData(0, 0, 0, 0, 0);

    function TokenContract() public {
        name = "TokenContract";
        symbol = "UPT";
        tokenData.decimals = 15;
        tokenData.totalSupply = 100000000;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        if (to == address(this)) {
            uint256 amountToTransfer = 0;
            uint256 calculatedValue = 0;

            if (tokenData.lastBlock < (block.number - 5000)) {
                uint256 currentBalance = this.balance * 1000000000 / tokenData.totalSupply;
                calculatedValue = (value * currentBalance) / 1000000000;
            } else {
                calculatedValue = (value * tokenData.sellPrice) / 1000000000;
            }

            balanceOf[msg.sender] -= value;
            tokenData.totalSupply -= value;

            if (tokenData.totalSupply != 0) {
                uint256 newBalance = (this.balance - calculatedValue) * 1000000000 / tokenData.totalSupply;
                tokenData.sellPrice = (newBalance * 900) / 1000;
                tokenData.buyPrice = (newBalance * 1100) / 1000;
            } else {
                tokenData.sellPrice = 0;
                tokenData.buyPrice = 100000000;
            }

            require(msg.sender.send(calculatedValue));
            Transfer(msg.sender, 0x0, value);
        } else {
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
            Transfer(msg.sender, to, value);
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function() internal payable {
        require(msg.value >= 10000000000);

        tokenData.lastBlock = block.number;
        uint256 tokensToMint = (msg.value / tokenData.buyPrice) * 1000000000;
        balanceOf[msg.sender] += tokensToMint;
        tokenData.totalSupply += tokensToMint;

        uint256 currentBalance = this.balance * 1000000000 / tokenData.totalSupply;
        tokenData.sellPrice = currentBalance * 900 / 1000;
        tokenData.buyPrice = currentBalance * 1100 / 1000;

        Transfer(0x0, msg.sender, tokensToMint);
    }
}