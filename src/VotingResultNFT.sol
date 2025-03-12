// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VotingResultNFT is ERC721, Ownable {
    uint256 public tokenIdCounter;

    struct VoteOutcome {
        uint256 voteId;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 finalizedAt;    // Block timestamp
        bool passed;            // "yes" beat "no"?
    }

    // Mapping from tokenId => the outcome data
    mapping(uint256 => VoteOutcome) public outcomes;

    constructor() ERC721("VotingResult", "VRS") Ownable(msg.sender) {}

    function mintVoteOutcome(
        address to,
        uint256 _voteId,
        string memory _description,
        uint256 _yesVotes,
        uint256 _noVotes,
        bool _passed
    ) external onlyOwner returns (uint256) {
        tokenIdCounter++;
        uint256 newTokenId = tokenIdCounter;

        // Mint the NFT
        _safeMint(to, newTokenId);

        // Store the outcome data on-chain
        outcomes[newTokenId] = VoteOutcome({
            voteId: _voteId,
            description: _description,
            yesVotes: _yesVotes,
            noVotes: _noVotes,
            finalizedAt: block.timestamp,
            passed: _passed
        });

        return newTokenId;
    }
}
