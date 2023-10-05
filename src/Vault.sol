// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol"; 

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStEth } from "./interfaces/IStEth.sol";
import { IOracle } from "./interfaces/IOracle.sol";

import { YToken } from "./YToken.sol";
import { HodlToken } from "./HodlToken.sol";

contract Vault {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION_FACTOR = 1 ether;

    IStEth public constant stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    YToken public immutable yToken;
    HodlToken public immutable hodlToken;

    IOracle public immutable oracle;

    uint256 public immutable strike;
    bool public didTrigger = false;
    uint256 public claimed;
    uint256 public immutable deployedAt;
    uint256 public immutable deployedRoundId;

    constructor(string memory name_,
                string memory symbol_,
                uint256 strike_,
                address oracle_) {

        // Strike price with 8 decimals
        strike = strike_;

        yToken = new YToken(address(this),
                            string.concat("y", symbol_),
                            string.concat("Yield ", name_));

        hodlToken = new HodlToken(address(this),
                                  string.concat("hodl", symbol_),
                                  string.concat("Hodl ", name_));

        oracle = IOracle(oracle_);

        deployedAt = block.timestamp;
        deployedRoundId = oracle.roundId();
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function mint() external payable {
        // TODO: rework this so that we don't need the '- 1' part

        // subtract 1 to account for stETH behavior
        hodlToken.mint(msg.sender, msg.value - 1);
        // mint yToken second for proper accounting
        yToken.mint(msg.sender, msg.value - 1);

        stEth.submit{value: msg.value}(address(0));
    }

    function redeem(uint256 amount) external {
        hodlToken.burn(msg.sender, amount);
        // burn yToken second for proper accounting
        yToken.burn(msg.sender, amount);

        amount = _min(amount, stEth.balanceOf(address(this)));
        stEth.transfer(msg.sender, amount);
    }

    function disburse(address recipient, uint256 amount) external {
        require(msg.sender == address(yToken) || msg.sender == address(hodlToken));
        IERC20(stEth).safeTransfer(recipient, amount);
        claimed += amount;
    }

    function trigger(uint80 roundId) external {
        require(oracle.timestamp(roundId) >= deployedAt, "timestamp");
        require(oracle.price(roundId) >= strike, "strike");
        yToken.trigger();
        didTrigger = true;  // do this in the middle for proper accounting
        hodlToken.trigger();
    }

    function cumulativeYield() external view returns (uint256) {
        uint256 delta = stEth.balanceOf(address(this)) - yToken.totalSupply();
        uint256 result = delta + claimed;
        return result;
    }
}
