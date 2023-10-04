// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol"; 

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ERC20 } from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

import { Vault } from "./Vault.sol";

contract HodlToken is ERC20, Ownable {

    Vault public immutable vault;

    constructor(address vault_,
                string memory name_,
                string memory symbol_) ERC20(name_, symbol_) {

        require(msg.sender == vault_);
        vault = Vault(vault_);
    }

    function trigger() external onlyOwner {
    }

    function claimable(address user) external view returns (uint256) {
        return 0;
    }

    function claim() external {
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external onlyOwner {
        uint256 bal = IERC20(address(this)).balanceOf(recipient);
        console.log("Bal", bal);
        require(bal >= amount);
        _burn(recipient, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
    }
}
