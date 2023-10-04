// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Vault } from  "../src/Vault.sol";
import { FakeOracle } from  "../test/helpers/FakeOracle.sol";

import { BaseScript } from "./BaseScript.sol";

contract DeployScript is BaseScript {
    using SafeERC20 for IERC20;

    Vault public vault;
    FakeOracle public oracle;

    function run() public {
        init();


        vm.startBroadcast(pk);

        oracle = new FakeOracle();
        oracle.setPrice(1611_00000000);

        vault = new Vault("ETH @ 1700",
                          "1700",
                          1700_00000000,
                          address(oracle));

        vm.stopBroadcast();

        {
            string memory objName = string.concat("deploy");
            string memory json;

            json = vm.serializeAddress(objName, "address_oracle", address(oracle));
            json = vm.serializeAddress(objName, "address_vault", address(vault));

            json = vm.serializeString(objName, "contractName_oracle", "FakeOracle");
            json = vm.serializeString(objName, "contractName_vault", "Vault");

            if (eq(vm.envString("NETWORK"), "mainnet")) {
                vm.writeJson(json, string.concat("./json/deploy-eth.ethereum.json"));
            } else if (eq(vm.envString("NETWORK"), "localhost")) {
                vm.writeJson(json, string.concat("./json/deploy-eth.localhost.json"));
            } else if (eq(vm.envString("NETWORK"), "fork")) {
                vm.writeJson(json, string.concat("./json/deploy-eth.fork.json"));
            }
        }
     }
}
