pragma solidity ^0.4.18;

contract Oxcdaff377583fb1d8af278abe42048c505685d239 {
    address public owner;
    uint256 public doomsday;
    uint256 public blessings;
    address public lastSender;
    uint256 public lifePoints;
    uint256 public tithes;

    function Oxcdaff377583fb1d8af278abe42048c505685d239() public payable {
        owner = msg.sender;
        doomsday = now + 10800;
        lastSender = msg.sender;
        blessings += msg.value;
    }

    function Ox410945a4cb2d3929c882b6582cf58836781ff072() public payable {
        require(msg.value >= 0.001 ether);
        if (now > doomsday) {
            doomsday = now + 10800;
        }
        blessings += msg.value * 8;
        tithes += msg.value * 2 / 10;
        lastSender = msg.sender;
        doomsday = now + 1800;
        lifePoints += 1;
    }

    function Oxb04c3051247195833ccdfdaef279fd93bc8d24a3() public {
        require(msg.sender == lastSender);
        require(now > doomsday);
        uint256 pendingBlessings = blessings;
        blessings = 0;
        lastSender.transfer(pendingBlessings);
        doomsday = now + 10800;
    }

    function Oxc18ff232ccd93b8b14a711cd022676b3dea5cf75() public {
        uint256 pendingTithes = tithes;
        tithes = 0;
        owner.transfer(pendingTithes);
    }
}