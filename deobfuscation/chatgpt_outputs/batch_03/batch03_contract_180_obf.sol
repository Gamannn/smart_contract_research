pragma solidity ^0.5.2;

contract Counter {
    event Incremented(uint256 newValue);

    struct CounterState {
        uint256 value;
    }

    CounterState private counterState = CounterState(0);

    constructor() public payable {
        counterState.value = 0;
    }

    function increment() public payable {
        counterState.value += 1;
        emit Incremented(counterState.value);
    }
}