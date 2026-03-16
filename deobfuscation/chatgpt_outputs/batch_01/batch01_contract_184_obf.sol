pragma solidity ^0.4.11;

contract MinerShare {
    address public owner = 0x0;
    uint public totalWithdrawn = 0;
    uint public userCount = 0;

    event LogAddUser(address newUser);
    event LogRemoveUser(address removedUser);
    event LogWithdraw(address sender, uint amount);

    mapping(address => uint) public userStatus;
    mapping(address => uint) public userWithdrawn;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyMember() {
        require(userStatus[msg.sender] != 0);
        _;
    }

    function MinerShare() {
        owner = msg.sender;
    }

    function addUser(address newUser) onlyOwner {
        if (userStatus[newUser] == 0) {
            userStatus[newUser] = 1;
            userCount += 1;
            LogAddUser(newUser);
        }
    }

    function removeUser(address removedUser) onlyOwner {
        if (userStatus[removedUser] == 1) {
            userStatus[removedUser] = 0;
            userCount -= 1;
            LogRemoveUser(removedUser);
        }
    }

    function withdraw() onlyMember {
        uint totalBalance = this.balance + totalWithdrawn;
        uint availableWithdraw = totalBalance / userCount - userWithdrawn[msg.sender];
        userWithdrawn[msg.sender] += availableWithdraw;
        totalWithdrawn += availableWithdraw;

        if (availableWithdraw > 0) {
            msg.sender.transfer(availableWithdraw);
            LogWithdraw(msg.sender, availableWithdraw);
        } else {
            revert();
        }
    }

    function () payable {}
}