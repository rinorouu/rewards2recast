// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract P2L is PermissionsEnumerable {
    struct Campaign {
        address advertiser;
        uint256 budget;
        uint256 rewardPerUser;
        uint256 maxParticipants;
        uint256 deadline;
        address[] participants;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignId;

    event CampaignCreated(uint256 indexed campaignId, address advertiser);
    event RewardClaimed(uint256 indexed campaignId, address participant);

    // Fee platform (2%)
    uint256 public constant FEE_PERCENT = 2;

    // Membuat campaign baru
    function createCampaign(
        uint256 _budget,
        uint256 _rewardPerUser,
        uint256 _maxParticipants,
        uint256 _durationHours
    ) external payable {
        require(msg.value == _budget, "Budget does not match");
        require(_rewardPerUser * _maxParticipants <= _budget, "Not enough budget");

        campaignId++;
        campaigns[campaignId] = Campaign({
            advertiser: msg.sender,
            budget: _budget,
            rewardPerUser: _rewardPerUser,
            maxParticipants: _maxParticipants,
            deadline: block.timestamp + (_durationHours * 1 hours),
            participants: new address[](0)
        });

        emit CampaignCreated(campaignId, msg.sender);
    }

    // Klaim hadiah oleh peserta
    function claimReward(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp <= campaign.deadline, "Campaign sudah berakhir");
        require(campaign.participants.length < campaign.maxParticipants, "Kuota habis");
        require(!_hasParticipated(_campaignId, msg.sender), "Sudah klaim");

        // Transfer reward ke peserta (98% setelah fee)
        uint256 fee = (campaign.rewardPerUser * FEE_PERCENT) / 100;
        uint256 reward = campaign.rewardPerUser - fee;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer fail");

        campaign.participants.push(msg.sender);
        emit RewardClaimed(_campaignId, msg.sender);
    }

    // Cek apakah alamat sudah berpartisipasi
    function _hasParticipated(uint256 _campaignId, address _user) internal view returns (bool) {
        for (uint256 i = 0; i < campaigns[_campaignId].participants.length; i++) {
            if (campaigns[_campaignId].participants[i] == _user) {
                return true;
            }
        }
        return false;
    }
}
