// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol"; 

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IOracle } from  "../src/interfaces/IOracle.sol";
import { IStEth } from "../src/interfaces/IStEth.sol";

import { Vault } from  "../src/Vault.sol";
import { ChainLinkOracle } from  "../src/ChainLinkOracle.sol";

import { BaseTest } from  "./BaseTest.sol";
import { FakeOracle } from  "./helpers/FakeOracle.sol";

contract VaultTest is BaseTest {
    Vault public vault;

    function setUp() public {
        init();
    }

    function testOracle() public {
        IOracle oracle;
        uint256 fork;
        fork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 18250000);
        vm.selectFork(fork);

        oracle = new ChainLinkOracle(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
        uint256 price1 = oracle.price(0);
        assertEq(168250110000, price1);

        fork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 18260000);
        vm.selectFork(fork);

        oracle = new ChainLinkOracle(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
        uint256 price2 = oracle.price(0);
        assertEq(172777012306, price2);
    }

    function testVault() public {
        uint256 fork;
        fork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 18250000);
        vm.selectFork(fork);
        init();

        FakeOracle oracle = new FakeOracle();
        oracle.setPrice(1611_00000000);

        // Create the vault, price < 1700
        vault = new Vault("ETH @ 1700",
                          "1700",
                          1700_00000000,
                          address(oracle));

        assertEq(0, vault.cumulativeYield());

        console.log("made vault", address(vault));
        console.log("vault.stEth()", address(vault.stEth()));
        console.log("whale balance", whale.balance);

        // Give the whale some stETH
        vm.startPrank(whale);
        IStEth(vault.stEth()).submit{value: 1 ether}(address(0));
        vm.stopPrank();

        // Alice mints y1700 and hodl1700
        console.log("alice bal", alice.balance / 1 ether);

        vm.startPrank(alice);
        vault.mint{value: 1 ether}();
        vm.stopPrank();

        assertEq(1 ether - 1, vault.yToken().balanceOf(alice));
        assertEq(1 ether - 1, vault.hodlToken().balanceOf(alice));
        assertEq(0, address(vault).balance);
        assertEq(1 ether - 1, IERC20(vault.stEth()).balanceOf(address(vault)));

        vm.expectRevert("strike");
        vault.trigger(0);

        // Some time passes, price still < 1700, Alice claims yield on y1700


        // Send stETH to vault to simulate incremental yield
        assertEq(0, vault.cumulativeYield());
        simulateYield(0.05 ether);
        assertEq(0.05 ether - 1, vault.cumulativeYield());

        uint256 claimable = vault.yToken().claimable(alice);
        uint256 cumulative = vault.cumulativeYield();

        vm.startPrank(alice);
        vault.yToken().claim();
        vm.stopPrank();

        // Some more incremental yield, then transfer, then more yield, then check claims
        simulateYield(0.01 ether);

        vm.startPrank(alice);
        vault.yToken().transfer(bob, 0.5 ether);
        vm.stopPrank();

        simulateYield(0.01 ether);

        console.log("--");

        {
            uint256 claimableA = vault.yToken().claimable(alice);
            uint256 claimableB = vault.yToken().claimable(bob);
            console.log("claimableA", claimableA);
            console.log("claimableB", claimableB);

            assertEq(14999999999999998, claimableA);
            assertEq(5000000000000000, claimableB);
        }


        vm.startPrank(bob);
        vault.yToken().transfer(alice, 0.5 ether);
        vm.stopPrank();

        simulateYield(0.01 ether);

        assertEq(24999999999999997, vault.yToken().claimable(alice));
        assertEq(5000000000000000, vault.yToken().claimable(bob));

        {
            console.log("==> Alice is claiming");

            uint256 before = IERC20(vault.stEth()).balanceOf(alice);
            vm.startPrank(alice);
            vault.yToken().claim();
            vm.stopPrank();
            uint256 delta = IERC20(vault.stEth()).balanceOf(alice) - before;
            assertEq(24999999999999996, delta);
        }

        console.log("==> Bob is claiming");

        vm.startPrank(bob);
        vault.yToken().claim();
        vm.stopPrank();
        assertEq(4999999999999999, IERC20(vault.stEth()).balanceOf(bob));

        console.log("-->checking claimable");

        assertEq(0, vault.yToken().claimable(alice));
        assertEq(0, vault.yToken().claimable(bob));

        // Chad mints y1700, hodl1700, verify that yield accounting works
        vm.startPrank(chad);
        vault.mint{value: 2 ether}();
        vm.stopPrank();

        assertEq(0, vault.yToken().claimable(alice));
        assertEq(0, vault.yToken().claimable(bob));
        assertEq(0, vault.yToken().claimable(chad));

        assertEq(1 ether - 1, vault.yToken().balanceOf(alice));
        assertEq(0, vault.yToken().balanceOf(bob));
        assertEq(2 ether - 1, vault.yToken().balanceOf(chad));
        // Simulate yield, verify yield accounting
        simulateYield(0.06 ether);
        assertEq(0.14 ether, vault.cumulativeYield());

        assertEq(0.02 ether - 1, vault.yToken().claimable(alice));
        assertEq(0, vault.yToken().claimable(bob));
        assertEq(0.04 ether - 3, vault.yToken().claimable(chad));

        claimYield(alice);
        claimYield(bob);
        claimYield(chad);

        // Do some complicated token movements, verify yield accounting
        vm.startPrank(chad);
        vault.yToken().transfer(bob, 0.5 ether);
        vm.stopPrank();

        simulateYield(0.06 ether);

        assertEq(0.02 ether, vault.yToken().claimable(alice));
        assertEq(0.01 ether, vault.yToken().claimable(bob));
        assertEq(0.03 ether - 1, vault.yToken().claimable(chad));

        vm.startPrank(chad);
        vault.yToken().transfer(bob, 0.5 ether);
        vm.stopPrank();

        assertEq(1 ether - 1, vault.yToken().balanceOf(alice));
        assertEq(1 ether, vault.yToken().balanceOf(bob));
        assertEq(1 ether - 1, vault.yToken().balanceOf(chad));

        simulateYield(0.06 ether);

        assertEq(0.04 ether - 1, vault.yToken().claimable(alice));
        assertEq(0.03 ether - 1, vault.yToken().claimable(bob));
        assertEq(0.05 ether - 3, vault.yToken().claimable(chad));

        assertEq(0.03 ether - 2, claimYield(bob));
        assertEq(0, vault.yToken().claimable(bob));

        assertEq(0.04 ether - 1, vault.yToken().claimable(alice));
        assertEq(0, vault.yToken().claimable(bob));
        assertEq(0.05 ether - 3, vault.yToken().claimable(chad));

        vm.startPrank(chad);
        vault.yToken().transfer(bob, 1 ether - 1);
        vm.stopPrank();

        simulateYield(0.06 ether);

        assertEq(1 ether - 1, vault.yToken().balanceOf(alice));
        assertEq(2 ether - 1, vault.yToken().balanceOf(bob));
        assertEq(0, vault.yToken().balanceOf(chad));

        assertEq(0.06 ether - 1, vault.yToken().claimable(alice));
        assertEq(0.04 ether - 1, vault.yToken().claimable(bob));
        assertEq(0.05 ether - 3, vault.yToken().claimable(chad));

        // Some time passes, price still < 1700, Bob redeems for stETH
        vm.startPrank(alice);
        vm.stopPrank();

        vm.startPrank(bob);
        vault.yToken().approve(address(vault), 1 ether);
        vault.hodlToken().approve(address(vault), 1 ether);
        vault.redeem(1 ether);

        return;

        vm.stopPrank();

        // Chad transfers hodl1700 to Degen

        // Price hits 1700

        // Everyone claims yield, check that it worked correctly,
        // including yield on hodl1700
    }

    function simulateYield(uint256 amount) internal {
        vm.startPrank(whale);
        IERC20(vault.stEth()).transfer(address(vault), amount);
        vm.stopPrank();
    }

    function claimYield(address user) internal returns (uint256) {
        uint256 before = IERC20(vault.stEth()).balanceOf(address(user));
        vm.startPrank(user);
        vault.yToken().claim();
        vm.stopPrank();
        uint256 delta = IERC20(vault.stEth()).balanceOf(address(user)) - before;
        return delta;
    }
}
