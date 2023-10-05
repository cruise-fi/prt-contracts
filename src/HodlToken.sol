// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol"; 

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ERC20 } from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

import { Vault } from "./Vault.sol";
import { YToken } from "./YToken.sol";

contract HodlToken is YToken {

    constructor(address vault_,
                string memory name_,
                string memory symbol_) YToken(vault_, name_, symbol_) {
    }

    function isAccumulating() public override view returns (bool) {
        return vault.didTrigger();
    }
}
