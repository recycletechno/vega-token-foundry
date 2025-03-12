# Vega Vote - Deployment Information

## Deployed Contracts

### VegaVote (ERC20 Token)
- **Contract Address**: `0xe5e57acce878c6ed12420220323d483ce32c2101`
- **Transaction Hash**: `0x14e78cf378802cbe806c77fae1563eb8bc9a53e0c9078452923e37579e5f0fc9`
- **Network**: Sepolia Testnet (Chain ID: 11155111)
- **Explorer Link**: [View on Sepolia Etherscan](https://sepolia.etherscan.io/address/0xe5e57acce878c6ed12420220323d483ce32c2101)
- **Transaction Link**: [View Transaction](https://sepolia.etherscan.io/tx/0x14e78cf378802cbe806c77fae1563eb8bc9a53e0c9078452923e37579e5f0fc9)

### VotingResultNFT (ERC721 Token)
- **Contract Address**: `0x91f3243b3e52a2d6f78ccd0ab6aab74db66774e7`
- **Transaction Hash**: `0x4c98456a7f908e93fb29d84ac3fe8ef79a49c06844837c19cacc1c044f9692e1`
- **Network**: Sepolia Testnet (Chain ID: 11155111)
- **Explorer Link**: [View on Sepolia Etherscan](https://sepolia.etherscan.io/address/0x91f3243b3e52a2d6f78ccd0ab6aab74db66774e7)
- **Transaction Link**: [View Transaction](https://sepolia.etherscan.io/tx/0x4c98456a7f908e93fb29d84ac3fe8ef79a49c06844837c19cacc1c044f9692e1)

### Voting (Main Contract)
- **Contract Address**: `0x05dd8fdb79398d399a5e444817792de09d92fc0c`
- **Transaction Hash**: `0xd4cdf72b4d5c84869213c680a6c7e49d0e247e9c0f7cd04e25370dbea7071af4`
- **Network**: Sepolia Testnet (Chain ID: 11155111)
- **Explorer Link**: [View on Sepolia Etherscan](https://sepolia.etherscan.io/address/0x05dd8fdb79398d399a5e444817792de09d92fc0c)
- **Transaction Link**: [View Transaction](https://sepolia.etherscan.io/tx/0xd4cdf72b4d5c84869213c680a6c7e49d0e247e9c0f7cd04e25370dbea7071af4)
- **Constructor Arguments**:
  - VegaVote Token: `0xe5E57ACCE878c6Ed12420220323D483cE32c2101`
  - VotingResultNFT: `0x91F3243B3E52A2d6f78ccD0Ab6AAb74Db66774e7`

## Ownership Transfer
- The ownership of VotingResultNFT was transferred to the Voting contract
- **Transaction Hash**: `0x587cc70dcac776f1db8326e5c3f4ae99e3e59d4b041922c4d16654f260f1e182`
- **Transaction Link**: [View Transaction](https://sepolia.etherscan.io/tx/0x587cc70dcac776f1db8326e5c3f4ae99e3e59d4b041922c4d16654f260f1e182)

## Development

### Deploy

```shell
$ forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```
