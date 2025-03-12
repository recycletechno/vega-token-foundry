// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VegaVote} from "../src/VegaVote.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {Voting} from "../src/Voting.sol";

/**
 * @dev forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        VegaVote vega = new VegaVote();
        console.log("VegaVote deployed at:", address(vega));

        VotingResultNFT resultNFT = new VotingResultNFT();
        console.log("VotingResultNFT deployed at:", address(resultNFT));

        Voting voting = new Voting(address(vega), address(resultNFT));
        console.log("Voting deployed at:", address(voting));

        // Transfer ownership so that Voting can call mintVoteOutcome()
        resultNFT.transferOwnership(address(voting));
        console.log("NFT ownership transferred to Voting contract:", address(voting));

        vm.stopBroadcast();
    }
}
