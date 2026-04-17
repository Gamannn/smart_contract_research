```solidity
pragma solidity ^0.4.23;

interface TokenInterface {
    function transfer(address to, uint256 value) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
}

contract TokenSale {
    uint256 public tokenPrice;
    mapping(address => uint) public balances;
    TokenInterface public tokenContract;
    address public owner;
    bool public saleActive;

    constructor(address _tokenContract) public {
        tokenContract = TokenInterface(_tokenContract);
        owner = msg.sender;
        saleActive = true;
        tokenPrice = 1000000000; // Example token price
    }

    function buyTokens() public payable {
        require(saleActive);
        require(balances[msg.sender] == 0);
        require(msg.value >= tokenPrice);

        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance != 0);

        require(tokenContract.transfer(msg.sender, tokenPrice));
        balances[msg.sender] = 1;
    }

    function endSale() public returns (bool success) {
        require(msg.sender == owner);

        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance != 0);

        if (tokenBalance > 0) {
            tokenContract.transfer(owner, tokenBalance);
        }

        saleActive = false;
        return true;
    }

    function contractTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function setTokenPrice(uint256 newPrice) public returns (bool success) {
        require(msg.sender == owner);
        tokenPrice = newPrice;
        return true;
    }
}
```