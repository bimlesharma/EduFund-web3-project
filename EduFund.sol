// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CrowdFunding {
    // Struct to represent a crowdfunding campaign
    struct Campaign {
        address owner; // Campaign owner
        string title; // Campaign title
        string description; // Campaign description
        uint256 target; // Target funding amount
        uint256 deadline; // Campaign deadline
        uint256 amountCollected; // Total funds collected
        string image; // Campaign image
        address[] donators; // List of donor addresses
        uint256[] donations; // List of donation amounts
    }

    // Mapping from campaign ID to campaign struct
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0; // Total number of campaigns

    // Function to create a new crowdfunding campaign
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    // Function to allow a user to donate to a campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        require(amount > 0, "Please, donation value must be greater than 0.");
        require(_id < numberOfCampaigns, "Campaign with specified ID does not exist.");

        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        if (sent) {
            campaign.amountCollected += amount;
            disburseFunds(_id);
        }
    }

    // Function to disburse funds for a specific campaign
    function disburseFunds(uint256 _id) private {
        Campaign storage campaign = campaigns[_id];
        if (block.timestamp >= campaign.deadline && campaign.amountCollected >= campaign.target) {
            (bool sent, ) = payable(campaign.owner).call{value: campaign.amountCollected}("");
            require(sent, "Failed to send funds");

            delete campaign.donators;
            delete campaign.donations;
        }
    }

    // View function to get the list of donators and their donations for a specific campaign
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        require(_id < numberOfCampaigns, "Campaign with specified ID does not exist.");
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // View function to get all the campaigns created on the platform
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}
