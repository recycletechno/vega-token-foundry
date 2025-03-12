// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {Voting} from "../src/Voting.sol";

/**
 * @dev Usage: forge script script/DeployWithExternalToken.s.sol:DeployWithExternalToken --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract DeployWithExternalToken is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        
        address vegaTokenAddress = 0xD3835FE9807DAecc7dEBC53795E7170844684CeF;
        
        vm.startBroadcast(deployerKey);
        
        console.log("Using external VegaVote at:", vegaTokenAddress);

        VotingResultNFT resultNFT = new VotingResultNFT();
        console.log("VotingResultNFT deployed at:", address(resultNFT));

        Voting voting = new Voting(vegaTokenAddress, address(resultNFT));
        console.log("Voting deployed at:", address(voting));

        // Transfer ownership so that Voting can call mintVoteOutcome()
        resultNFT.transferOwnership(address(voting));
        console.log("NFT ownership transferred to Voting contract:", address(voting));

        vm.stopBroadcast();
    }
} 