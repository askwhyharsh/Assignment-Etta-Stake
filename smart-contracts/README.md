Stake deployed at 0xA6e36606b1c07FCFE0fA26ff3b9DF0653A2A5494  
https://sepolia.etherscan.io/address/0xa6e36606b1c07fcfe0fa26ff3b9df0653a2a5494

Stake: PACK-to-NFT System (Foundry)
Overview
- Contract `Stake` supports:
  - ETH staking → awards credits immediately at a configurable rate (`creditsPerEth`)
  - PACK purchase → users buy packs with ETH
  - NFT minting → convert a PACK to an ERC721 NFT by spending credits
  - Credit management → credits accumulate from staking and are consumed on mint
  - Proceeds model →
    - ETH from `buyPack` is owner proceeds
    - When minting, the ETH-equivalent of credits spent is converted from the user’s staked balance into owner proceeds

Key Concepts
- creditsPerEth: number of credits granted per 1 ETH staked. Example: if `creditsPerEth = 1000`, then staking 1 ETH awards 1000 credits; 0.5 ETH awards 500 credits.
- Pack: defined by `priceWei` (ETH to buy) and `creditCost` (credits to mint).
- Proceeds segregation: Owner can withdraw only `address(this).balance - totalStakedWei`.

Prerequisites
- Foundry installed (anvil/forge/cast). Install: https://book.getfoundry.sh/getting-started/installation
- Node optional (only for RPC management). 

Install Dependencies
```bash
cd assignment-etta/smart-contracts

# Install OpenZeppelin Contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# (Optional) Update remappings if needed
forge remappings > remappings.txt
```

Project Structure
- `src/Stake.sol` — main contract (Ownable, ReentrancyGuard, ERC721)
- `test/Stake.t.sol` — Foundry tests
- `script/Deploy.s.sol` — deployment script

Configure (optional)
- You can adjust initial packs and `creditsPerEth` in `script/Deploy.s.sol`.

Build
```bash
forge build
```

Test
```bash
# Run all tests
forge test -vvv

# Run a single test file
forge test -vvv --match-path test/Stake.t.sol

# Run a specific test
forge test -vvv --match-test testMintFromPackConsumesPackAndCreditsAndMintsNFT
```

Local Chain (optional)
```bash
# Start a local anvil node
anvil -p 8545

# In another shell, run tests against that RPC (if you want):
forge test --fork-url http://127.0.0.1:8545 -vvv
```

Deploy (Script)
The script expects an EOA private key via env var `PRIVATE_KEY`.

```bash
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY   # or any RPC

forge script script/Deploy.s.sol:Deploy \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast -vvvv
```

What the Script Does
- Deploys `Stake` with `creditsPerEth = 1000`
- Configures two sample packs:
  - Pack 1: price 0.1 ETH, creditCost 20
  - Pack 2: price 0.2 ETH, creditCost 30

Runtime Notes
- Staking
  - `stake()` accepts ETH, awards credits: `credits = (msg.value * creditsPerEth) / 1 ether`.
  - If the stake would yield 0 credits (too small), the call reverts.
  - `withdrawStake(amount)` lets users withdraw their still-unspent staked ETH.
- Buying Packs
  - `buyPack(packId, quantity)` requires exact ETH: `quantity * priceWei`.
- Minting
  - `mintFromPack(packId)` requires 1 available pack and `creditCost` credits.
  - On mint, the ETH-equivalent of spent credits is moved from the user’s staked balance to owner proceeds: `ethEquivalent = creditCost * 1 ether / creditsPerEth`.
  - If the user’s staked balance is insufficient to back the credit conversion, the mint reverts.
- Proceeds
  - `proceedsBalance()` shows how much ETH the owner can withdraw.
  - `withdrawProceeds(to, amount)` transfers only the proceeds (not staked user funds).

Security & Edge Cases
- Reentrancy-safe on ETH transfers and state mutations.
- Access control: only owner can configure packs/withdraw proceeds.
- Inactive/unknown packs revert on buy/mint.
- Mint converts credits only if user has corresponding staked ETH to back them.

Verification (Etherscan)
After deployment, verify with Foundry (adjust args and chain):
```bash
forge verify-contract \
  --chain sepolia \
  --num-of-optimizations 200 \
  --watch \
  <DEPLOYED_ADDRESS> \
  src/Stake.sol:Stake \
  <ETHERSCAN_API_KEY>
```

License
SPDX-License-Identifier: MIT

