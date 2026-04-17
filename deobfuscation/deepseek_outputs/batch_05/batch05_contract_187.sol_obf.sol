pragma solidity ^0.5.0;

contract Forwarder {
    event ForwarderCall(bool success);
    
    function forwardCall(
        address from,
        address to,
        bytes memory data
    ) public payable {
        (bool success, bytes memory returnData) = to.call.value(msg.value)(data);
        emit ForwarderCall(success);
    }
    
    function() external payable {}
}