pragma solidity ^0.5.0;

contract Forwarder {
    event ForwarderCall(bool success);

    function forwardCall(address payable target, bytes memory data) public payable {
        (bool success, ) = target.call.value(msg.value)(data);
        emit ForwarderCall(success);
    }

    function () external payable {}
}