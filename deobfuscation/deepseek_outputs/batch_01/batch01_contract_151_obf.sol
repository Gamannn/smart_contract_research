pragma solidity ^0.4.0;

contract RecoverableWallet {
    event ReclaimBegun();
    event Reclaimed();
    event Sent(address indexed to, uint value, bytes data);
    event Received(address indexed from, uint value, bytes data);
    event Reset();
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event BackupChanged(address indexed previousBackup, address indexed newBackup);
    event ReclaimPeriodChanged(uint previousPeriod, uint newPeriod);

    struct State {
        uint reclaimDeadline;
        uint reclaimPeriod;
        address backup;
        address owner;
    }

    State private state;

    function RecoverableWallet(address owner, address backup, uint reclaimPeriod) {
        state.owner = owner;
        state.backup = backup;
        state.reclaimPeriod = reclaimPeriod;
    }

    function() payable {
        Received(msg.sender, msg.value, msg.data);
    }

    function beginReclaim() onlyBackup onlyIfNotReclaiming {
        state.reclaimDeadline = now + state.reclaimPeriod;
        ReclaimBegun();
    }

    function executeReclaim() onlyBackup onlyIfReclaimable {
        state.owner = state.backup;
        state.reclaimDeadline = 0;
        Reclaimed();
    }

    function resetReclaim() onlyOwnerOrBackup {
        state.reclaimDeadline = 0;
        Reset();
    }

    function send(address to, uint value, bytes data) onlyOwner {
        if (!to.call.value(value)(data)) {
            revert();
        }
        Sent(to, value, data);
    }

    function changeOwner(address newOwner) onlyOwner {
        OwnerChanged(state.owner, newOwner);
        state.owner = newOwner;
    }

    function changeBackup(address newBackup) onlyOwner {
        BackupChanged(state.backup, newBackup);
        state.backup = newBackup;
    }

    function changeReclaimPeriod(uint newPeriod) onlyOwner {
        ReclaimPeriodChanged(state.reclaimPeriod, newPeriod);
        state.reclaimPeriod = newPeriod;
    }

    function isReclaiming() constant returns (bool) {
        return state.reclaimDeadline != 0;
    }

    function isReclaimable() constant returns (bool) {
        return state.reclaimDeadline != 0 && now > state.reclaimDeadline;
    }

    function timeUntilReclaim() constant onlyIfReclaiming returns (uint) {
        return now > state.reclaimDeadline ? 0 : state.reclaimDeadline - now;
    }

    modifier onlyOwner {
        if (msg.sender != state.owner) revert();
        _;
    }

    modifier onlyBackup {
        if (msg.sender != state.backup) revert();
        _;
    }

    modifier onlyOwnerOrBackup {
        if (msg.sender != state.backup && msg.sender != state.owner) revert();
        _;
    }

    modifier onlyIfReclaiming {
        if (state.reclaimDeadline == 0) revert();
        _;
    }

    modifier onlyIfNotReclaiming {
        if (state.reclaimDeadline == 0) _;
    }

    modifier onlyIfReclaimable {
        if (state.reclaimDeadline != 0 && now > state.reclaimDeadline) _;
    }
}