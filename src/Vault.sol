// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IStEth } from "../interfaces/IStEth.sol";
import { IOracle } from "../interfaces/IOracle.sol";

import { YToken } ffrom "./YToken.sol";
import { HodlToken } ffrom "./HodlToken.sol";

contract Vault {

    IStEth public constant stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    YToken public immutable yToken;
    HodlToken public immutable hodlToken;

    IOracle public immutable oracle;

    uint256 public immutable strike;
    bool didTrigger = false;

    constructor(string name_,
                string symbol_,
                uint256 strike_,
                address oracle_) {

        strike = strike_;

        yToken = new YToken(address(this),
                            string.concat("y", symbol_),
                            string.concat("Yield ", name_));

        hodlToken = new HodlToken(address(this),
                                  string.concat("hodl", symbol_),
                                  string.concat("Hodl ", name_));
        oracle = IOracle(oracle);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function mint() external payable {
        yToken.mint(msg.value);
        hodlToken.mint(msg.value);
        stEth.submit{value: msg.value}(address(0));
    }

    function redeem(uint256 amount) external {
        yToken.safeTransferFrom(msg.sender, address(this));
        hodlToken.safeTransferFrom(msg.sender, address(this));

        yToken.burn(amount);
        hodlToken.burn(amount);

        stEth.transfer(msg.sender, min(amount, stEth.balanceOf(address(this))));
    }

    function trigger(uint256 timestamp) {
        require(oracle.price(timestamp) >= strike, "strike");
        didTrigger = true;
        yToken.trigger();
        hodlToken.trigger();
    }
}
