// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol"; 

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

import { Vault } from "./Vault.sol";

contract YToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    Vault public immutable vault;

    /* uint256 public yieldPerToken = 0; */
    uint256 public cumulativeYieldAcc = 0;
    uint256 public yieldPerTokenAcc = 0;

    struct UserInfo {
        uint256 yieldPerTokenClaimed;
        uint256 accClaimable;
        uint256 claimed;
    }
    mapping (address => UserInfo) infos;

    constructor(address vault_,
                string memory name_,
                string memory symbol_) ERC20(name_, symbol_) {

        require(msg.sender == vault_);
        vault = Vault(vault_);
    }

    function trigger() external onlyOwner {
    }

    function _checkpointYieldPerToken() internal {
        yieldPerTokenAcc += _yieldPerToken();
        cumulativeYieldAcc += vault.cumulativeYield();
    }

    function _yieldPerToken() internal view returns (uint256) {
        if (totalSupply() == 0) return 0;
        uint256 deltaCumulative = vault.cumulativeYield() - cumulativeYieldAcc;
        uint256 incr = (deltaCumulative * vault.PRECISION_FACTOR()
                        / totalSupply());
        return yieldPerTokenAcc + incr;
    }

    function claimable(address user) public view returns (uint256) {
        UserInfo storage info = infos[user];
        uint256 yptBase = _yieldPerToken();
        uint256 ypt = yptBase - info.yieldPerTokenClaimed;

        console.log("");
        console.log("computing Claimable with YPT:", ypt);
        console.log("- ypt base", yptBase);
        console.log("- ypt info", info.yieldPerTokenClaimed);
        console.log("- and acc ", info.accClaimable);
        console.log("");

        uint256 result = (ypt * balanceOf(user) / vault.PRECISION_FACTOR()
                          + info.accClaimable);
        return result;
    }

    function claim() external {
        UserInfo storage info = infos[msg.sender];
        uint256 amount = claimable(msg.sender);
        if (amount == 0) return;

        uint256 yptBefore = _yieldPerToken();
        vault.disburse(msg.sender, amount);
        uint256 yptAfter = _yieldPerToken();

        console.log("yptBefore", yptBefore);
        console.log("yptAfter ", yptAfter);

        info.yieldPerTokenClaimed = _yieldPerToken();
        info.accClaimable = 0;

        console.log("info.yieldPerTokenClaimed set to", info.yieldPerTokenClaimed);
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _checkpointYieldPerToken();
        _mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external onlyOwner {
        require(IERC20(address(this)).balanceOf(recipient) >= amount);
        _checkpointYieldPerToken();
        _burn(recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        uint256 ypt = _yieldPerToken();

        infos[from].accClaimable = claimable(from);
        infos[from].yieldPerTokenClaimed = ypt;
        infos[to].accClaimable = claimable(to);
        infos[to].yieldPerTokenClaimed = ypt;
    }
}
