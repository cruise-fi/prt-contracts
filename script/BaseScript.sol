// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseScript is Script {
    using SafeERC20 for IERC20;
    using stdJson for string;

    uint256 pk;
    address deployerAddress;
    bool isDev;

    function eq(string memory str1, string memory str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function init() public {
        if (eq(vm.envString("NETWORK"), "mainnet")) {
            pk = vm.envUint("MAINNET_PRIVATE_KEY");
            deployerAddress = vm.envAddress("MAINNET_DEPLOYER_ADDRESS");
        } else if (eq(vm.envString("NETWORK"), "localhost")) {
            pk = vm.envUint("LOCALHOST_PRIVATE_KEY");
            deployerAddress = vm.envAddress("LOCALHOST_DEPLOYER_ADDRESS");
        } else if (eq(vm.envString("NETWORK"), "fork")) {
            pk = vm.envUint("FORK_PRIVATE_KEY");
            deployerAddress = vm.envAddress("FORK_DEPLOYER_ADDRESS");
        }
        isDev = (eq(vm.envString("NETWORK"), "localhost") || eq(vm.envString("NETWORK"), "fork"));
    }
}
