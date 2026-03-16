pragma solidity ^0.4.0;

contract ReclaimableContract {
    event ReclaimBegun();
    event Reclaimed();
    event Sent(address indexed to, uint amount, bytes data);
    event Received(address indexed from, uint amount, bytes data);
    event Reset();
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event BackupChanged(address indexed oldBackup, address indexed newBackup);
    event ReclaimPeriodChanged(uint oldPeriod, uint newPeriod);

    struct ContractState {
        uint256 reclaimDeadline;
        uint256 reclaimPeriod;
        address backupAddress;
        address ownerAddress;
    }

    ContractState state = ContractState(0, 0, address(0), address(0));

    function ReclaimableContract(address owner, address backup, uint reclaimPeriod) public {
        state.ownerAddress = owner;
        state.backupAddress = backup;
        state.reclaimPeriod = reclaimPeriod;
    }

    function() public payable {
        Received(msg.sender, msg.value, msg.data);
    }

    function beginReclaim() public onlyBackup onlyIfNotReclaimed {
        state.reclaimDeadline = now + state.reclaimPeriod;
        ReclaimBegun();
    }

    function reclaim() public onlyBackup onlyIfReclaimable {
        state.ownerAddress = state.backupAddress;
        state.reclaimDeadline = 0;
        Reclaimed();
    }

    function resetReclaim() public onlyOwnerOrBackup {
        state.reclaimDeadline = 0;
        Reset();
    }

    function sendFunds(address to, uint amount, bytes data) public onlyOwner {
        if (!to.call.value(amount)(data)) revert();
        Sent(to, amount, data);
    }

    function changeOwner(address newOwner) public onlyOwner {
        OwnerChanged(state.ownerAddress, newOwner);
        state.ownerAddress = newOwner;
    }

    function changeBackup(address newBackup) public onlyOwner {
        BackupChanged(state.backupAddress, newBackup);
        state.backupAddress = newBackup;
    }

    function changeReclaimPeriod(uint newPeriod) public onlyOwner {
        ReclaimPeriodChanged(state.reclaimPeriod, newPeriod);
        state.reclaimPeriod = newPeriod;
    }

    function isReclaiming() public view returns (bool) {
        return state.reclaimDeadline != 0;
    }

    function isReclaimable() public view returns (bool) {
        return state.reclaimDeadline != 0 && now > state.reclaimDeadline;
    }

    function timeUntilReclaim() public view onlyIfReclaiming returns (uint) {
        return now > state.reclaimDeadline ? 0 : state.reclaimDeadline - now;
    }

    modifier onlyOwner() {
        if (msg.sender != state.ownerAddress) revert();
        _;
    }

    modifier onlyBackup() {
        if (msg.sender != state.backupAddress) revert();
        _;
    }

    modifier onlyOwnerOrBackup() {
        if (msg.sender != state.backupAddress && msg.sender != state.ownerAddress) revert();
        _;
    }

    modifier onlyIfReclaiming() {
        if (state.reclaimDeadline == 0) revert();
        _;
    }

    modifier onlyIfNotReclaimed() {
        if (state.reclaimDeadline == 0) _;
    }

    modifier onlyIfReclaimable() {
        if (state.reclaimDeadline != 0 && now > state.reclaimDeadline) _;
    }
}