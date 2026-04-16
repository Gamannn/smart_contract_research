pragma solidity >=0.4.10;

contract TokenInterface {
    function balanceOf(address account) public view returns (uint);
    function transfer(address recipient, uint amount) public returns (bool);
}

contract Crowdsale {
    address public owner;
    string public name;
    uint public startTime;
    uint public endTime;
    uint public cap;
    bool public isSaleActive;

    event StartSale();
    event EndSale();
    event EtherReceived(address sender, uint amount);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function startSale() public onlyOwner {
        require(block.timestamp >= startTime);
        if (block.timestamp > endTime || address(this).balance > cap) {
            require(isSaleActive);
            isSaleActive = false;
            emit EndSale();
        }
        if (!isSaleActive) {
            isSaleActive = true;
            emit StartSale();
        }
        emit EtherReceived(msg.sender, msg.value);
    }

    function setSaleParameters(uint _startTime, uint _endTime, uint _cap) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
    }

    function withdrawFunds() public onlyOwner {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }

    function withdrawPartialFunds(uint amount) public onlyOwner {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
    }

    function transferTokens(address tokenAddress) public onlyOwner {
        TokenInterface token = TokenInterface(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))));
    }

    function transferTokensTo(address tokenAddress, address recipient, uint amount) public onlyOwner {
        TokenInterface token = TokenInterface(tokenAddress);
        require(token.transfer(recipient, amount));
    }
}