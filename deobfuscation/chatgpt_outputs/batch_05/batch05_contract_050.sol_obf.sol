```solidity
pragma solidity ^0.4.24;

contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

contract Crowdsale {
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refunds;
    bool public isFinalized;
    bool public isActive;
    uint256 public totalRaised;
    uint256 constant public minContribution = 1 ether;
    address constant public creator = 0xf58546F5CDE2a7ff5C91AFc63B43380F0C198BE8;
    address public wallet;
    bytes32 public secretHash = 0x8d9b2b8f1327f8bad773f0f3af0cb4f3fbd8abfad8797a28d1d01e354982c7de;
    uint256 public creatorFee;
    TokenInterface public token;

    constructor(address _wallet, address _token) public {
        require(_wallet != address(0));
        require(_token != address(0));
        wallet = _wallet;
        token = TokenInterface(_token);
    }

    function contribute() public payable {
        require(!isFinalized);
        require(isActive);
        contributions[msg.sender] += msg.value;
    }

    function finalize() public {
        require(msg.sender == creator);
        require(!isFinalized);
        isFinalized = true;
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance / 100;
        creatorFee = balance - creatorShare;
        wallet.transfer(creatorShare);
        creator.transfer(creatorFee);
    }

    function claimRefund() public {
        require(isFinalized);
        uint256 amount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function withdrawTokens() public {
        require(isFinalized);
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        require(token.transfer(msg.sender, amount));
    }

    function setWallet(address _wallet) public {
        require(msg.sender == creator);
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function setToken(address _token) public {
        require(msg.sender == creator);
        require(_token != address(0));
        token = TokenInterface(_token);
    }

    function setSecretHash(bytes32 _secretHash) public {
        require(msg.sender == creator);
        secretHash = _secretHash;
    }

    function () external payable {
        contribute();
    }
}
```