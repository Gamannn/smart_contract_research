```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Token is ApproveAndCallFallBack {
    uint256 public MAGNITUDE = 100000000000000;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    
    ERC20Interface public tokenContract = ERC20Interface(0x5BD574410F3A2dA202bABBa1609330Db02aD64C2);
    
    event BoughtToken(uint tokens, uint eth, address indexed buyer);
    event SoldToken(uint tokens, uint eth, address indexed seller);
    
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        require(tokenContract.approve(address(this), tokens));
        require(msg.sender == address(tokenContract));
        
        uint256 ethAmount = calculateTokenSell(tokens);
        tokenContract.transferFrom(from, address(this), tokens);
        from.transfer(ethAmount);
        
        emit SoldToken(tokens, ethAmount, from);
    }
    
    function buyTokens() public payable {
        require(tokenContract.approve(address(this), msg.value));
        uint256 tokens = calculateTokenBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        tokenContract.transfer(msg.sender, tokens);
        emit BoughtToken(tokens, msg.value, msg.sender);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(MAGNITUDE, bs),
            SafeMath.add(
                PSN,
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(PSN, rs),
                        SafeMath.mul(PSNH, rt)
                    ),
                    rt
                )
            )
        );
    }
    
    function calculateTokenSell(uint256 tokens) public view returns(uint256) {
        return calculateTrade(tokens, tokenContract.balanceOf(address(this)), address(this).balance);
    }
    
    function calculateTokenBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, tokenContract.balanceOf(address(this)));
    }
    
    function calculateTokenBuySimple(uint256 eth) public view returns(uint256) {
        return calculateTokenBuy(eth, address(this).balance);
    }
    
    function() public payable {}
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getTokenBalance() public view returns(uint256) {
        return tokenContract.balanceOf(address(this));
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

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
```