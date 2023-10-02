// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IStEth is (IERC20) {
    function submit(address) external payable;
}
