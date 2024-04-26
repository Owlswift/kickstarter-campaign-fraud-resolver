pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(string campaignDescription, uint campaignMinimumContribution) public {
        address newCampaign = new Campaign(campaignDescription, campaignMinimumContribution, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct SpendRequest {
        string description;
        uint amount;
        uint approvalCount;
        mapping(address => bool) approvals;
        bool isComplete;
        address recipient;
    }
    
    address public campaign;
    string public description;
    uint public minimumContribution;
    mapping(address => uint) contributors;
    uint public contributorsCount;
    address public manager;
    SpendRequest[] public requests;

    modifier isManager() {
        require(msg.sender == manager);
        _;
    }

    function Campaign(string campaignDescription, uint campaignMinimumContribution, address campaignCreator) public {
        manager = campaignCreator;
        description = campaignDescription;
        minimumContribution = campaignMinimumContribution;
    }

    function supportCampaign(uint contribution) public payable {
        require(msg.value >= minimumContribution);

        contributors[msg.sender] = contribution;
        contributorsCount++;
    }

    function createRequest(string requestDescription, uint requestAmount, address requestVendor) public isManager {
        SpendRequest memory newRequest = SpendRequest({
            description: requestDescription,
            amount: requestAmount,
            approvalCount: 0,
            isComplete: false,
            recipient: requestVendor
        });

        requests.push(newRequest);
    }

    function approveRequest(uint requestIndex) public {
        SpendRequest storage currentRequest = requests[requestIndex];

        require(contributors[msg.sender] > 0);
        require(!currentRequest.approvals[msg.sender]);

        currentRequest.approvals[msg.sender] = true;
        currentRequest.approvalCount++;
    }

    function finalizeRequest(uint requestIndex) public isManager {
        SpendRequest storage currentRequest = requests[requestIndex];

        require(!currentRequest.isComplete);
        require(currentRequest.approvalCount > (contributorsCount/2));

        currentRequest.recipient.transfer(currentRequest.amount);
        currentRequest.isComplete = true;
    }

}