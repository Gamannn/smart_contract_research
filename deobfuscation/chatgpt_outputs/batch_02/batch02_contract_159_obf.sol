pragma solidity ^0.4.18;

contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
}

contract TokenSale {
    address public owner;
    bool public isActive;
    uint256 public rate;
    uint256 public endTime;
    address public tokenAddress;
    event Redemption(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    modifier onlyActive() {
        require(isActive);
        require(now < endTime);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function TokenSale(address _owner, address _tokenAddress, uint256 _rate, uint256 _endTime) public {
        owner = _owner;
        tokenAddress = _tokenAddress;
        rate = _rate;
        endTime = _endTime;
        isActive = true;
    }

    function () public payable onlyActive {
        uint256 tokenAmount = msg.value * rate;
        require(TokenInterface(tokenAddress).transfer(msg.sender, tokenAmount));
        finalizeSale();
        Redemption(tokenAddress, msg.sender, msg.value, tokenAmount);
    }

    function redeemTokens(uint256 tokenAmount) public onlyActive {
        require(TokenInterface(tokenAddress).transferFrom(msg.sender, this, tokenAmount));
        uint256 ethAmount = tokenAmount / rate;
        msg.sender.transfer(ethAmount);
        Redemption(msg.sender, ethAmount, tokenAmount);
    }

    function finalizeSale() public {
        if (now > endTime) {
            isActive = false;
        }
        uint256 tokenBalance = TokenInterface(tokenAddress).balanceOf(this);
        if (tokenBalance < rate) {
            isActive = false;
        }
    }

    function withdrawTokens(uint256 tokenAmount) public onlyOwner {
        require(TokenInterface(tokenAddress).transfer(msg.sender, tokenAmount));
        Redemption(msg.sender, 0, tokenAmount);
    }

    function withdrawTokensFrom(address from, uint256 tokenAmount) public onlyOwner {
        require(TokenInterface(tokenAddress).transferFrom(from, msg.sender, tokenAmount));
        Redemption(from, 0, tokenAmount);
    }
}