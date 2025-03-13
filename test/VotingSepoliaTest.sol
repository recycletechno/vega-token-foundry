// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {VegaVote} from "../src/VegaVote.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {Voting} from "../src/Voting.sol";

/**
 * @title VotingSepoliaTest
 * @dev Tests for deployed contracts on Sepolia
 * Run with: forge test --match-contract VotingSepoliaTest --fork-url $SEPOLIA_RPC_URL
 */
contract VotingSepoliaTest is Test {
    // Deployed contract addresses on Sepolia
    address public tokenAddress = 0xe5E57ACCE878c6Ed12420220323D483cE32c2101;
    address public nftAddress = 0x91F3243B3E52A2d6f78ccD0Ab6AAb74Db66774e7;
    address public votingAddress = 0x05dd8Fdb79398D399A5E444817792dE09D92Fc0c;
    
    // Contract interfaces
    VegaVote public token;
    VotingResultNFT public nft;
    Voting public voting;
    uint256 public tokenMultiplier; // Multiplier based on token decimals

    // Test addresses
    address owner = 0xb5F848c40484081352E45f3e034b927d11dF9047; // Actual deployer from the JSON
    address satoshi = address(0xB);
    address vitalik = address(0xC);
    address donald = address(0xD);

    function setUp() public {
        // Create a fork of Sepolia
        vm.createSelectFork("sepolia");
        
        // Connect to the deployed contracts
        token = VegaVote(tokenAddress);
        nft = VotingResultNFT(nftAddress);
        voting = Voting(votingAddress);
        
        // Set token multiplier based on decimals
        tokenMultiplier = 10 ** token.decimals();

        // Fund test accounts
        vm.deal(satoshi, 10 ether);
        vm.deal(vitalik, 10 ether);
        vm.deal(donald, 10 ether);

        // Mint tokens to test users (as owner)
        vm.startPrank(owner);
        token.mint(satoshi, 1000 * tokenMultiplier);
        token.mint(vitalik, 500 * tokenMultiplier);
        token.mint(donald, 200 * tokenMultiplier);
        vm.stopPrank();
    }

    /**
     * @dev Test that token minting works correctly
     */
    function testTokenMinting() public view {
        assertEq(token.balanceOf(satoshi), 1000 * tokenMultiplier, "Satoshi should have 1000 tokens");
        assertEq(token.balanceOf(vitalik), 500 * tokenMultiplier, "Vitalik should have 500 tokens");
        assertEq(token.balanceOf(donald), 200 * tokenMultiplier, "Donald should have 200 tokens");
    }

    /**
     * @dev Test only the staking functionality
     */
    function testStaking() public {
        // Satoshi stakes
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        vm.stopPrank();

        // Check Satoshi's token balance after staking
        assertEq(token.balanceOf(satoshi), 800 * tokenMultiplier, "Satoshi should have 800 tokens left after staking");
        
        // Check Satoshi's stake info
        (uint256 amount, uint256 endTime, uint256 stakeYears) = voting.stakes(satoshi);
        assertEq(amount, 200 * tokenMultiplier, "Stake amount should be 200 tokens");
        assertEq(stakeYears, 4, "Stake years should be 4");
        assertGt(endTime, block.timestamp, "Stake end time should be in the future");
    }

    /**
     * @dev Test that staking with invalid parameters fails
     */
    function testCannotStakeInvalidParams() public {
        vm.startPrank(satoshi);
        token.approve(address(voting), 1000 * tokenMultiplier);
        
        // Cannot stake 0 tokens
        vm.expectRevert("Cannot stake 0");
        voting.stakeTokens(0, 2);
        
        // Cannot stake for less than 1 year
        vm.expectRevert("Stake in [1..4] years");
        voting.stakeTokens(100 * tokenMultiplier, 0);
        
        // Cannot stake for more than 4 years
        vm.expectRevert("Stake in [1..4] years");
        voting.stakeTokens(100 * tokenMultiplier, 5);
        
        vm.stopPrank();
    }

    /**
     * @dev Test that a user cannot stake twice
     */
    function testCannotStakeTwice() public {
        vm.startPrank(satoshi);
        token.approve(address(voting), 1000 * tokenMultiplier);
        
        // First stake should succeed
        voting.stakeTokens(100 * tokenMultiplier, 2);
        
        // Second stake should fail
        vm.expectRevert("Already staked");
        voting.stakeTokens(100 * tokenMultiplier, 3);
        
        vm.stopPrank();
    }

    /**
     * @dev Test vote creation
     */
    function testVoteCreation() public {
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        // Check vote was created with correct parameters
        (string memory description, uint256 deadline, uint256 threshold, uint256 yesVotes, uint256 noVotes, bool active) = voting.votes(1);

        assertNotEq(bytes(description).length, 0, "Vote description should not be empty");
        assertEq(description, "Should we sell BTC now?", "Vote description should match");
        assertEq(deadline, block.timestamp + 1 days, "Vote deadline should match");
        assertEq(threshold, 4000 * tokenMultiplier, "Vote threshold should match");
        assertEq(yesVotes, 0, "Yes votes should start at 0");
        assertEq(noVotes, 0, "No votes should start at 0");
        assertTrue(active, "Vote should be active");
    }

    /**
     * @dev Test that only owner can create votes
     */
    function testOnlyOwnerCanCreateVote() public {
        vm.prank(satoshi);
        vm.expectRevert(); // Ownable: caller is not the owner
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
    }

    /**
     * @dev Test vote casting
     */
    function testVoteCasting() public {
        // Setup: Create a vote and stake tokens
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        voting.castVote(1, true); // Satoshi votes YES
        vm.stopPrank();
        
        vm.startPrank(vitalik);
        token.approve(address(voting), 100 * tokenMultiplier);
        voting.stakeTokens(100 * tokenMultiplier, 2);
        voting.castVote(1, false); // Vitalik votes NO
        vm.stopPrank();
        
        // Check vote counts
        (, , , uint256 yesVotes, uint256 noVotes, ) = voting.votes(1);
        
        // Satoshi's voting power: 200 * (4^2) = 200 * 16 = 3200
        assertEq(yesVotes, 200 * tokenMultiplier * 16, "Yes votes should match Satoshi's voting power");
        
        // Vitalik's voting power: 100 * (2^2) = 100 * 4 = 400
        assertEq(noVotes, 100 * tokenMultiplier * 4, "No votes should match Vitalik's voting power");
    }

    /**
     * @dev Test that a user cannot vote twice
     */
    function testCannotVoteTwice() public {
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        
        // First vote should succeed
        voting.castVote(1, true);
        
        // Second vote should fail
        vm.expectRevert("Already voted");
        voting.castVote(1, true);
        
        vm.stopPrank();
    }

    /**
     * @dev Test that a user cannot vote after the deadline
     */
    function testCannotVoteAfterDeadline() public {
        // Setup: Create a vote and stake tokens
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        
        // Move time forward past the deadline
        vm.warp(block.timestamp + 2 days);
        
        // Vote should fail
        vm.expectRevert("Vote deadline passed");
        voting.castVote(1, true);
        
        vm.stopPrank();
    }

    /**
     * @dev Test that a user cannot vote without staking
     */
    function testCannotVoteWithoutStaking() public {
        // Setup: Create a vote
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        // Donald tries to vote without staking
        vm.prank(donald);
        vm.expectRevert("No voting power");
        voting.castVote(1, true);
    }

    /**
     * @dev Test vote finalization
     */
    function testVoteFinalization() public {
        // Setup: Create a vote and cast votes
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        voting.castVote(1, true); // Satoshi votes YES
        vm.stopPrank();
        
        vm.startPrank(vitalik);
        token.approve(address(voting), 100 * tokenMultiplier);
        voting.stakeTokens(100 * tokenMultiplier, 2);
        voting.castVote(1, false); // Vitalik votes NO
        vm.stopPrank();
        
        // Move time forward
        vm.warp(block.timestamp + 2 days);
        
        // Owner finalizes the vote
        vm.prank(owner);
        voting.finalizeVote(1);
        
        // Check vote is no longer active
        (, , , , , bool active) = voting.votes(1);
        assertFalse(active, "Vote should not be active after finalization");
    }

    /**
     * @dev Test that only owner can finalize votes
     */
    function testOnlyOwnerCanFinalizeVote() public {
        // Setup: Create a vote
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        // Move time forward
        vm.warp(block.timestamp + 2 days);
        
        // Satoshi tries to finalize the vote
        vm.prank(satoshi);
        vm.expectRevert(); // Ownable: caller is not the owner
        voting.finalizeVote(1);
    }

    /**
     * @dev Test that a vote cannot be finalized before the deadline
     */
    function testCannotFinalizeBeforeDeadline() public {
        // Setup: Create a vote
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        // Owner tries to finalize before deadline
        vm.prank(owner);
        vm.expectRevert("Deadline not reached");
        voting.finalizeVote(1);
    }

    /**
     * @dev Test NFT minting after vote finalization
     */
    function testNFTMinting() public {
        // Setup: Create a vote, cast votes, and finalize
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);
        
        vm.startPrank(satoshi);
        token.approve(address(voting), 200 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4);
        voting.castVote(1, true); // Satoshi votes YES
        vm.stopPrank();
        
        // Move time forward
        vm.warp(block.timestamp + 2 days);
        
        // Owner finalizes the vote
        vm.prank(owner);
        voting.finalizeVote(1);
        
        // Check NFT was minted
        uint256 tokenId = nft.tokenIdCounter();
        assertEq(tokenId, 1, "NFT should have been minted");
        assertEq(nft.ownerOf(tokenId), owner, "NFT should be owned by owner");
        
        // Check NFT data
        (
            uint256 voteId,
            string memory description,
            uint256 yesVotes,
            uint256 noVotes,
            ,  // finalizedAt (unused)
            bool passed
        ) = nft.outcomes(tokenId);
        
        assertEq(voteId, 1, "NFT vote ID should match");
        assertEq(description, "Should we sell BTC now?", "NFT description should match");
        assertEq(yesVotes, 200 * tokenMultiplier * 16, "NFT yes votes should match");
        assertEq(noVotes, 0, "NFT no votes should match");
        assertTrue(passed, "Vote should have passed");
    }

    /**
     * @dev Test the full voting flow (integration test)
     */
    function testFullVotingFlow() public {
        // Satoshi stakes
        vm.startPrank(satoshi);
        token.approve(address(voting), 1000 * tokenMultiplier);
        voting.stakeTokens(200 * tokenMultiplier, 4); 
        vm.stopPrank();

        // Vitalik stakes
        vm.startPrank(vitalik);
        token.approve(address(voting), 500 * tokenMultiplier);
        voting.stakeTokens(100 * tokenMultiplier, 2);
        vm.stopPrank();

        // Owner creates a vote
        vm.prank(owner);
        voting.createVote("Should we sell BTC now?", block.timestamp + 1 days, 4000 * tokenMultiplier);

        // Satoshi votes YES
        vm.startPrank(satoshi);
        voting.castVote(1, true); 
        vm.stopPrank();

        // Vitalik votes NO
        vm.startPrank(vitalik);
        voting.castVote(1, false);
        vm.stopPrank();

        // Move time forward
        vm.warp(block.timestamp + 2 days);

        // Owner finalizes
        vm.prank(owner);
        voting.finalizeVote(1);

        // Check NFT was minted with correct data
        uint256 tokenId = nft.tokenIdCounter();
        
        // Get individual components from the outcomes mapping
        (
            uint256 voteId,
            string memory description,
            uint256 yesVotes,
            uint256 noVotes,
            ,  // finalizedAt (unused)
            bool passed
        ) = nft.outcomes(tokenId);

        // Check results
        assertEq(voteId, 1);
        assertEq(description, "Should we sell BTC now?");
        assertEq(yesVotes, 200 * tokenMultiplier * (4**2)); // 200 * 16
        assertEq(noVotes, 100 * tokenMultiplier * (2**2));  // 100 * 4
        assertTrue(passed);
    }
} 