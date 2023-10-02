// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IOracle {
    function price(uint256 timestamp) external returns (uint256);
}