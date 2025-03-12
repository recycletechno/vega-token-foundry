// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VotingResultNFT} from "./VotingResultNFT.sol";
import {console} from "forge-std/console.sol";

contract Voting is Ownable {
    // Reference to the ERC20 token (mock in local, real on Sepolia)
    IERC20 public vegaToken;

    // Reference to the NFT contract
    VotingResultNFT public resultNFT;

    // Info about a single user's stake (simple single-stake version)
    struct StakeInfo {
        uint256 amount;       // how many tokens staked
        uint256 stakeEndTime; // block.timestamp when lock ends
        uint256 stakeYears;   // 1..4
    }

    // Mapping from user to their single stake
    mapping(address => StakeInfo) public stakes;

    struct Vote {
        string description;  // The question asked
        uint256 deadline;    // block.timestamp after which the vote ends
        uint256 threshold;   // if yes/no meets this count, vote ends early
        uint256 yesVotes;
        uint256 noVotes;
        bool active;         // true while voting is ongoing
    }

    // Each new vote gets an incrementing ID
    uint256 public currentVoteId;

    // Mapping voteId => Vote
    mapping(uint256 => Vote) public votes;

    // Mapping voteId => (user => bool) to track if user has already voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /**
     * @dev Emitted when a new vote is created.
     */
    event VoteCreated(uint256 voteId, string description, uint256 deadline, uint256 threshold);

    /**
     * @dev Emitted when a user casts a vote.
     */
    event VoteCast(uint256 voteId, address voter, bool support, uint256 votingPower);

    /**
     * @dev Emitted when a vote is finalized.
     */
    event VoteFinalized(uint256 voteId, uint256 yesVotes, uint256 noVotes, bool passed);

    /**
     * @param _vegaToken The address of the ERC20 token
     * @param _resultNFT The address of the VotingResultNFT
     */
    constructor(address _vegaToken, address _resultNFT) Ownable(msg.sender) {
        vegaToken = IERC20(_vegaToken);
        resultNFT = VotingResultNFT(_resultNFT);
    }

    function stakeTokens(uint256 _amount, uint256 _years) external {
        require(_years >= 1 && _years <= 4, "Stake in [1..4] years");
        require(_amount > 0, "Cannot stake 0");
        require(stakes[msg.sender].amount == 0, "Already staked"); // Simple single-stake version

        bool success = vegaToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        uint256 lockEnd = block.timestamp + (_years * 365 * 24 * 60 * 60);

        stakes[msg.sender] = StakeInfo({
            amount: _amount,
            stakeEndTime: lockEnd,
            stakeYears: _years
        });
    }

    function unstakeTokens() external {
        StakeInfo memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stake found");
        require(block.timestamp >= stake.stakeEndTime, "Stake is still locked");
        
        bool success = vegaToken.transfer(msg.sender, stake.amount);
        require(success, "Token transfer failed");
        
        delete stakes[msg.sender];
    }

    /**
     * @dev Creates a new vote that token stakers can participate in.
     * @param _description A string describing what the vote is about
     * @param _deadline The timestamp (in seconds) when the vote will end
     * @param _threshold The number of votes required to end the vote early
     * @notice Only the contract owner can create votes
     */
    function createVote(
        string calldata _description,
        uint256 _deadline,
        uint256 _threshold
    ) external onlyOwner {
        require(_deadline > block.timestamp, "Deadline must be in future");
        require(_threshold > 0, "Threshold must be > 0");
        require(bytes(_description).length > 0, "Description must be non-empty");

        // Each vote should have a unique ID - guaranteed by incrementing currentVoteId
        currentVoteId++;
        votes[currentVoteId] = Vote({
            description: _description,
            deadline: _deadline,
            threshold: _threshold,
            yesVotes: 0,
            noVotes: 0,
            active: true
        });

        emit VoteCreated(currentVoteId, _description, _deadline, _threshold);
    }

    function castVote(uint256 _voteId, bool _support) external {
        Vote storage vote = votes[_voteId];
        require(vote.active, "Vote not active");
        require(block.timestamp < vote.deadline, "Vote deadline passed");
        require(!hasVoted[_voteId][msg.sender], "Already voted");

        uint256 votingPower = _getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        // console.log("Voting power: %s", votingPower);

        if (_support) {
            vote.yesVotes += votingPower;
        } else {
            vote.noVotes += votingPower;
        }

        hasVoted[_voteId][msg.sender] = true;
        emit VoteCast(_voteId, msg.sender, _support, votingPower);

        // Check threshold. We may have different thresholds for yes and no or maybe sum of them
        if (vote.yesVotes >= vote.threshold || vote.noVotes >= vote.threshold) {
            _finalizeVote(_voteId);
        }
    }

    /**
     * @dev OnlyOwner can finalize after the deadline
     *      In case threshold wasn't reached early
     *      We may use external oracle to finalize or our own trigger logic (server)
     */
    function finalizeVote(uint256 _voteId) external onlyOwner {
        Vote storage vote = votes[_voteId];
        require(vote.active, "Vote already finalized");
        require(block.timestamp >= vote.deadline, "Deadline not reached");

        _finalizeVote(_voteId);
    }

    /**
     * @dev Internal function to finalize the vote and mint an NFT with results.
     */
    function _finalizeVote(uint256 _voteId) internal {
        Vote storage vote = votes[_voteId];
        vote.active = false;

        bool passed = (vote.yesVotes > vote.noVotes);

        // Emit event
        emit VoteFinalized(_voteId, vote.yesVotes, vote.noVotes, passed);

        // console.log("Vote outcome: %s finalized", vote.description);

        resultNFT.mintVoteOutcome(
            owner(),
            _voteId,
            vote.description,
            vote.yesVotes,
            vote.noVotes,
            passed
        );
    }

    function _getVotingPower(address _user) internal view returns (uint256) {
        StakeInfo memory stake = stakes[_user];
        if (stake.amount == 0) {
            return 0;
        }
        return stake.amount * (stake.stakeYears ** 2);
    }
}
