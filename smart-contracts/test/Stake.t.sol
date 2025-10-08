// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Stake.sol";

contract StakeTest is Test {
    Stake internal stake;
    address internal owner = address(0xABCD);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    // Test configuration
    uint256 internal constant CREDITS_PER_ETH = 1000; // 1 ETH -> 1000 credits, 0.001 eth per credit

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        vm.prank(owner);
        stake = new Stake(CREDITS_PER_ETH);

        // Transfer ownership to explicit owner test address if not already
        // Deployer becomes owner by default; transfer not required since we deployed via owner prank

        // Configure two packs
        vm.prank(owner);
        stake.setPack(1, 0.1 ether, 2000, true); // price: 0.1 ETH, credit cost: 2000
        vm.prank(owner);
        stake.setPack(2, 0.2 ether, 3000, true);
    }

    function testStakeAwardsCreditsAndTracksTotal() public {
        vm.prank(alice);
        stake.stake{value: 1 ether}();

        assertEq(stake.stakedBalanceWei(alice), 1 ether);
        assertEq(stake.creditsOf(alice), (1 ether * CREDITS_PER_ETH) / 1 ether);
    }

    function testWithdrawStake() public {
        vm.startPrank(alice);
        stake.stake{value: 2 ether}();
        stake.withdrawStake(1 ether);
        vm.stopPrank();

        assertEq(stake.stakedBalanceWei(alice), 1 ether);
    }

    function testBuyPackRequiresExactEth() public {
        vm.startPrank(alice);
        vm.expectRevert(bytes("incorrect eth"));
        stake.buyPack{value: 0.09 ether}(1, 1);

        stake.buyPack{value: 0.1 ether}(1, 1);
        assertEq(stake.userPackBalance(alice, 1), 1);
        vm.stopPrank();
    }

    function testMintFromPackConsumesPackAndCreditsAndMintsNFT() public {
        // Alice stakes 2 ETH -> gets 2000 credits/ETH * 2 = 2000? No, configured 1000 credits/ETH
        // credits = 2 * 1000 = 2000 credits
        vm.prank(alice);
        stake.stake{value: 2 ether}();

        // Needs 2000 credits for pack 1
        vm.prank(alice);
        stake.buyPack{value: 0.1 ether}(1, 1);

        vm.prank(alice);
        uint256 tokenId = stake.mintFromPack(1);

        assertEq(tokenId, 1);
        assertEq(stake.balanceOf(alice), 1);
        assertEq(stake.userPackBalance(alice, 1), 0);
        // should be 0 
        assertEq(stake.creditsOf(alice), 0);
        assertEq(stake.ownerOf(1), alice);

        // Proceeds from credit conversion: creditCost=2000, creditsPerEth=1000 ether => 2000/1000 * 1 ether = 2 ether
        // Alice staked 2 ether, so her staked balance should drop to 0
        assertEq(stake.stakedBalanceWei(alice), 0);
        // Owner can now withdraw 0.1 (pack price) + 2 ether (credit conversion) = 2.1 ether
        // But in this test we only bought 1 pack for 0.1, and converted credits worth 2.0 ETH to proceeds.
        // We don't withdraw here, just ensure proceedsBalance >= 2.1 ether
        assertGe(stake.proceedsBalance(), 2.1 ether);
    }

    function testMintFromPackInsufficientCreditsReverts() public {
        vm.startPrank(alice);
        // stake 1 ETH -> 1000 credits
        stake.stake{value: 1 ether}();
        // buy pack 1 (needs 2000 credits)
        stake.buyPack{value: 0.1 ether}(1, 1);
        vm.expectRevert();
        stake.mintFromPack(1);
        vm.stopPrank();
    }

    function testWithdrawProceedsOnlyOwnerAndNotTouchingStakes() public {
        // Alice buys packs: proceeds in contract
        vm.prank(alice);
        stake.buyPack{value: 0.2 ether}(1, 2); // 0.2 ether proceeds

        // Non-owner cannot withdraw
        vm.prank(alice);
        vm.expectRevert();
        stake.withdrawProceeds(payable(alice), 0.1 ether);

        // Owner can withdraw up to proceeds
        uint256 beforeOwner = owner.balance;
        vm.prank(owner);
        stake.withdrawProceeds(payable(owner), 0.2 ether);
        assertEq(owner.balance, beforeOwner + 0.2 ether);

        // If there are staked funds, they cannot be withdrawn as proceeds
        vm.prank(bob);
        stake.stake{value: 1 ether}();
        vm.prank(owner);
        vm.expectRevert(bytes("insufficient proceeds"));
        stake.withdrawProceeds(payable(owner), 0.1 ether);
    }

    function testInvalidPackAndInactivePack() public {
        // Pack 999 inactive by default
        vm.prank(alice);
        vm.expectRevert(bytes("pack inactive"));
        stake.buyPack{value: 0.1 ether}(999, 1);

        // Deactivate pack 1
        vm.prank(owner);
        stake.setPack(1, 0.1 ether, 2000, false);

        vm.prank(alice);
        vm.expectRevert(bytes("pack inactive"));
        stake.buyPack{value: 0.1 ether}(1, 1);
    }
}


