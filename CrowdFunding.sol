// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <= 0.9.0;

contract CrowdFunding {
   
    mapping(address => uint) public contributors; // user address -> amt for contribution

    address public manager;
    uint public minimumContribution; // user need to pay min amt of ethers to donate
    uint public deadline;
    uint public target; // manager has set the target
    uint public raisedAmount; 
    uint public noOfContributors; // this has done because to get the perrcentage

    struct Request{
        string description; // reason for request
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address => bool) voters;
    }

    mapping(uint => Request) public requests; // to keep the track of requests with proper index and also we can create multiple request
    uint public numRequests;

    // creation of manager using constructor
    constructor(uint _target,uint _deadline)public{
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    // by using payable keyword we can make function to pay to contract
    function sendEther() public payable{
        require(block.timestamp < deadline,"Deadline has passed" );
        require(msg.value >= minimumContribution,"Minimum contribution is not met");

        if(contributors[msg.sender] == 0){
            noOfContributors+=1;
        }

        contributors[msg.sender] += msg.value; // we have made addition because if contributor pays multiple time it should be added not over written
        raisedAmount = raisedAmount + msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    // making refund function
    function refund() public {
        require(raisedAmount < target && block.timestamp > deadline,"Your amount cannot be refunded");
        require(contributors[msg.sender] > 0,"Chutiya");

        address payable user = msg.sender;
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }


    // creating the request to access the funds only manager access

    modifier onlyManager(){
        require(msg.sender == manager,"Only manager can call this function");
        _;
    }

    function createRequest(string memory _description,address payable _recipient,uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests]; // accessing from map
        // user can create multiple requests so we are using map to create it
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false; // payment to party is completed or not
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public{
        
        require(contributors[msg.sender] > 0,"You have not contributed to anything");

        Request storage thisRequest = requests[_requestNo];

        // checking wether a person has voted previously
        require(thisRequest.voters[msg.sender] == false,"you have already voted"); // bydefault it will be false so it will be checked
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    // transferring the money to the particular party or benificiary
    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount >= target,"Target not reached");

        Request storage thisRequest = requests[_requestNo]; 
        
        require(thisRequest.completed == false,"This request has been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2,"Majority does not exist");

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

    }

}