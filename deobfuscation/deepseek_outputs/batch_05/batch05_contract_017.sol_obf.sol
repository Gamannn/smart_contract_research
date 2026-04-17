```solidity
pragma solidity ^0.4.18;

contract ERC20 {
    function totalSupply() constant public returns (uint totalSupply);
    function balanceOf(address owner) constant public returns (uint balance);
    function transfer(address to, uint amount) public returns (bool success);
    function transferFrom(address from, address to, uint amount) public returns (bool success);
    function approve(address spender, uint amount) public returns (bool success);
    function allowance(address owner, address spender) constant public returns (uint remaining);
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    address public constant tokenAddress = 0x574c4DB1E399859753A09D65b6C5586429663701;
    address public constant wallet1 = 0xd58f863De3bb877F24996291cC3C659b3550d58e;
    address public constant wallet2 = 0x4dF46817dc0e8dD69D7DA51b0e2347f5EFdB9671;
    address public constant wallet3 = 0x8b0e368aF9d27252121205B1db24d9E48f62B236;
    
    uint256 public tokensSold;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public share1;
    uint256 public share2;
    uint256 public share3;
    address public tokenHolder;
    address public priceSetter;
    address public fundsReceiver;
    address public tokenContract;
    
    event GotTokens(address indexed buyer, uint256 ethSent, uint256 tokensReceived);
    
    function TokenSale() public {
        tokensSold = 0;
        sellPrice = 0;
        buyPrice = 5;
        share1 = 0;
        share2 = 21;
        share3 = 800;
        tokenHolder = address(0);
        priceSetter = 0x574c4DB1E399859753A09D65b6C5586429663701;
        fundsReceiver = 0xd58f863De3bb877F24996291cC3C659b3550d58e;
        tokenContract = tokenAddress;
    }
    
    function buyTokens() payable public {
        uint256 tokensToBuy = msg.value / buyPrice;
        uint256 tokenBalance = ERC20(tokenContract).balanceOf(address(this));
        uint256 refund = 0;
        uint256 cost = tokensToBuy * buyPrice;
        
        if (msg.value > cost) {
            refund = msg.value - cost;
        }
        
        if (refund > 0) {
            if (!msg.sender.send(refund)) revert();
        }
        
        if (tokensToBuy > tokenBalance) {
            if (!ERC20(tokenContract).transfer(msg.sender, tokensToBuy)) revert();
        } else {
            uint256 amount1 = msg.value * share1 / 1000;
            uint256 amount2 = msg.value * share2 / 1000;
            uint256 amount3 = msg.value * share3 / 1000;
            
            if (!wallet1.send(amount1)) revert();
            if (!wallet2.send(amount2)) revert();
            if (!wallet3.send(amount3)) revert();
            
            GotTokens(msg.sender, msg.value, tokensToBuy);
        }
    }
    
    function () payable public {
        buyTokens();
    }
    
    function getAddressConstant(uint256 index) internal view returns(address payable) {
        address payable[] memory addressConstants = new address payable[](4);
        addressConstants[0] = 0xd58f863De3bb877F24996291cC3C659b3550d58e;
        addressConstants[1] = 0x4dF46817dc0e8dD69D7DA51b0e2347f5EFdB9671;
        addressConstants[2] = 0x8b0e368aF9d27252121205B1db24d9E48f62B236;
        addressConstants[3] = 0x574c4DB1E399859753A09D65b6C5586429663701;
        return addressConstants[index];
    }
    
    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        uint256[] memory integerConstants = new uint256[](7);
        integerConstants[0] = 5;
        integerConstants[1] = 2122;
        integerConstants[2] = 0;
        integerConstants[3] = 1000000000000;
        integerConstants[4] = 800;
        integerConstants[5] = 100;
        integerConstants[6] = 1000;
        return integerConstants[index];
    }
}
```