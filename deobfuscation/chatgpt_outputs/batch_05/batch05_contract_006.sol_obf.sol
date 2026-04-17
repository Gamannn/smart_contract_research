pragma solidity ^0.5.8;

contract ContributionContract {
    struct Contribution {
        uint256 redTeamAmount;
        uint256 blueTeamAmount;
        address payable beneficiary;
    }

    Contribution contributions = Contribution(0, 0, 0x82338B1b27cfC0C27D79c3738B748f951Ab1a7A0);

    uint256[] public integerConstants = [0, 2, 1];
    address payable[] public addressConstants = [0x82338B1b27cfC0C27D79c3738B748f951Ab1a7A0];

    function withdraw() public {
        contributions.beneficiary.transfer(address(this).balance);
    }

    function contributeToBlueTeam() public payable {
        contributions.blueTeamAmount += msg.value;
    }

    function contributeToRedTeam() public payable {
        contributions.redTeamAmount += msg.value;
    }

    function() external payable {
        if (msg.value % 2 == 0) {
            contributions.redTeamAmount += msg.value;
        } else {
            contributions.blueTeamAmount += msg.value;
        }
    }

    function getLeadingTeam() public view returns (uint256) {
        if (contributions.blueTeamAmount > contributions.redTeamAmount) {
            return 1; // Blue team is leading
        } else if (contributions.blueTeamAmount < contributions.redTeamAmount) {
            return 2; // Red team is leading
        }
        return 0; // Tie
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getAddressConstant(uint256 index) internal view returns (address payable) {
        return addressConstants[index];
    }
}