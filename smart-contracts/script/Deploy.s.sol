// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Stake.sol";

/*
  Deploy.s.sol

  Example Foundry script to deploy the Stake contract, set initial parameters, and log addresses.

  Usage:
  - Local: forge script script/Deploy.s.sol:Deploy --rpc-url <RPC> --private-key <KEY> --broadcast -vvvv
  - Sepolia: set RPC/PK env vars or Foundry profile accordingly.
*/

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Configure initial credits per ETH; e.g., 1000 credits per ETH -> 0.001 eth per credit
        Stake stake = new Stake(1000);

        // Configure sample packs
        stake.setPack(1, 0.1 ether, 20, true); // required 20 credits to convert 1 pack to NFT
        stake.setPack(2, 0.2 ether, 30, true); // required 30 credits to convert 1 pack to NFT

        vm.stopBroadcast();

        console2.log("Stake deployed at", address(stake));
    }
}

