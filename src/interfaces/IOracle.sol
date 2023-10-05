// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IOracle {
    function price(uint80 roundId) external returns (uint256);
    function timestamp(uint80 roundId) external returns (uint256);
    function roundId() external returns (uint80);
}
