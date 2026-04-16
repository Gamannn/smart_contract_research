pragma solidity ^0.5.2;

contract Counter {
    event Incremented(uint256 value);
    
    struct State {
        uint256 value;
    }
    
    State private state = State(0);
    
    constructor() public payable {
        state.value = 0;
    }
    
    function increment() public payable {
        state.value += 1;
        emit Incremented(state.value);
    }
}