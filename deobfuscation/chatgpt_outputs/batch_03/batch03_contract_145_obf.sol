pragma solidity ^0.4.18;

contract PixelGrid {
    event PixelUpdate(uint32 indexed pixelIndex, uint8 color);

    byte[500000] public pixelData;

    struct OwnerData {
        address owner;
        uint256 price;
    }

    OwnerData ownerData = OwnerData(address(0), 0);

    function PixelGrid(uint256 initialPrice) public {
        ownerData.owner = msg.sender;
        ownerData.price = initialPrice;
    }

    function updatePixel(uint32 pixelIndex, uint8 color) public payable {
        require(pixelIndex < 1000000);
        require(msg.value >= ownerData.price);

        uint32 byteIndex = pixelIndex / 2;
        byte currentByte = pixelData[byteIndex];
        bool isEven = pixelIndex % 2 == 0;
        byte newByte;

        if (isEven) {
            newByte = (currentByte & hex'0f') | bytes1(color * 2 ** 4);
        } else {
            newByte = (currentByte & hex'f0') | (bytes1(color) & hex'0f');
        }

        pixelData[byteIndex] = newByte;
        PixelUpdate(pixelIndex, color);
    }

    function getPixelData() public constant returns (byte[500000]) {
        return pixelData;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerData.owner);
        _;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        ownerData.price = newPrice;
    }

    function withdraw() public onlyOwner {
        ownerData.owner.transfer(this.balance);
    }

    function() public payable { }
}