```solidity
pragma solidity ^0.4.16;

library MathLibrary {
    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a / b;
        return result;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        assert(result >= a);
        return result;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract TokenInterface {
    function balanceOf(address account) public constant returns (uint);
    function transfer(address to, uint amount) public;
}

contract Admin {
    address public admin;

    event TransferAdminship(address newAdmin);
    event Admined(address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function Admin(address initialAdmin) public {
        admin = initialAdmin;
        Admined(admin);
    }

    function transferAdminship(address newAdmin) onlyAdmin public {
        require(newAdmin != address(0));
        admin = newAdmin;
        TransferAdminship(admin);
    }
}

contract TokenSale is Admin {
    uint256 public startTime = now;
    uint256 public tokenPrice = 1 ether;
    TokenInterface public tokenContract;
    address public wallet;
    string public campaignName;

    event TokenBought(address buyer, uint256 amount);
    event TokenWithdrawal(address to, uint256 amount);
    event PayOut(address to, uint256 amount);

    function TokenSale(address tokenAddress, string campaign) public {
        tokenContract = TokenInterface(tokenAddress);
        admin = msg.sender;
        wallet = msg.sender;
        campaignName = campaign;
    }

    function withdrawTokens(address to) onlyAdmin public {
        require(to != address(0));
        require(tokenContract.balanceOf(this) > 0);
        uint256 tokenBalance = tokenContract.balanceOf(this);
        tokenContract.transfer(to, tokenBalance);
        TokenWithdrawal(to, tokenBalance);
    }

    function withdrawEther() onlyAdmin public {
        require(this.balance > 0);
        uint256 etherBalance = this.balance;
        require(wallet.send(etherBalance));
        PayOut(wallet, etherBalance);
    }

    function () public payable {
        // Fallback function to receive Ether
    }
}
```