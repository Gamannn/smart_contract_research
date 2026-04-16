pragma solidity ^0.4.18;

contract PixelCanvas {
    event PixelUpdate(uint32 indexed pixelIndex, uint8 color);

    byte[500000] public canvasData;

    struct ContractState {
        address owner;
        uint256 price;
    }

    ContractState private state = ContractState(address(0), 0);

    function PixelCanvas(uint256 initialPrice) public {
        state.owner = msg.sender;
        state.price = initialPrice;
    }

    function setPixel(uint32 pixelIndex, uint8 color) public payable {
        require(pixelIndex < 1000000);
        require(msg.value >= state.price);

        uint32 storageIndex = pixelIndex / 2;
        byte currentByte = canvasData[storageIndex];
        bool isEven = pixelIndex % 2 == 0;
        byte newByte;

        if (isEven) {
            newByte = (currentByte & hex'0f') | bytes1(color * 2 ** 4);
        } else {
            newByte = (currentByte & hex'f0') | (bytes1(color) & hex'0f');
        }

        canvasData[storageIndex] = newByte;
        PixelUpdate(pixelIndex, color);
    }

    function getCanvas() public constant returns (byte[500000]) {
        return canvasData;
    }

    modifier onlyOwner() {
        require(msg.sender == state.owner);
        _;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        state.price = newPrice;
    }

    function withdraw() public onlyOwner {
        state.owner.transfer(this.balance);
    }

    function() public payable {}
}