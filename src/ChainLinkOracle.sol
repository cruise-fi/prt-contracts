// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol"; 

import { IOracle } from "./interfaces/IOracle.sol";

import { AggregatorV3Interface } from "./interfaces/chainlink/AggregatorV3Interface.sol";

contract ChainLinkOracle is IOracle {
    AggregatorV3Interface public immutable feed;

    constructor(address feed_) {
        feed = AggregatorV3Interface(feed_);
    }

    // Returns price with 8 decimals
    function price(uint80 roundId) external returns (uint256) {
        if (roundId == 0) {
            ( , int256 result, , , ) = feed.latestRoundData();
            if (result < 0) return 0;
            return uint256(result);
        } else {
            ( , int256 result, , , ) = feed.getRoundData(roundId);
            if (result < 0) return 0;
            return uint256(result);
        }
    }

    function timestamp(uint80 roundId) external returns (uint256) {
        if (roundId == 0) {
            ( , , , uint256 result , ) = feed.latestRoundData();
            return result;
        } else {
            ( , , , uint256 result , ) = feed.getRoundData(roundId);
            return result;
        }
    }
}
