pragma solidity ^0.4.11;

contract TokenInterface {
    function transfer(address to, uint amount);
    function balanceOf(address owner) constant returns (uint balance);
}

contract TokenSale {
    mapping (address => uint256) public tokenBalance;
    mapping (address => uint256) public etherBalance;
    uint256 public totalTokensSold = 52500;
    uint256 public totalEtherCollected;
    address owner = 0xB00Ae1e677B27Eee9955d632FF07a8590210B366;
    bool public saleActive = false;
    TokenInterface public tokenContract = TokenInterface(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);

    function activateSale() {
        if (msg.sender != owner) throw;
        saleActive = true;
    }

    function deactivateSale() {
        if (msg.sender != owner) throw;
        saleActive = false;
    }

    function claimTokens() payable {
        if (block.number > 4199999 && tokenBalance[msg.sender] > tokenContract.balanceOf(address(this))) {
            uint256 etherAmount = etherBalance[msg.sender];
            if (etherAmount == 0 || tokenBalance[msg.sender] == 0) throw;
            totalTokensSold -= tokenBalance[msg.sender];
            tokenBalance[msg.sender] = 0;
            msg.sender.transfer(etherAmount);
            return;
        }
        if (tokenContract.balanceOf(address(this)) == 0 || tokenBalance[msg.sender] > tokenContract.balanceOf(address(this))) throw;
        uint256 tokenAmount = tokenBalance[msg.sender];
        uint256 etherAmount = etherBalance[msg.sender];
        if (tokenAmount == 0 || etherAmount == 0) throw;
        tokenBalance[msg.sender] = 0;
        etherBalance[msg.sender] = 0;
        tokenContract.transfer(msg.sender, tokenAmount);
        owner.transfer(etherAmount);
    }

    function buyTokens() payable {
        if (saleActive) throw;
        uint256 tokensToBuy = 160 * msg.value;
        if ((totalEtherCollected + tokensToBuy) > totalTokensSold) throw;
        tokenBalance[msg.sender] += tokensToBuy;
        etherBalance[msg.sender] += msg.value;
        totalEtherCollected += tokensToBuy;
    }

    function () payable {
        if (msg.value == 0) {
            claimTokens();
        } else {
            buyTokens();
        }
    }
}