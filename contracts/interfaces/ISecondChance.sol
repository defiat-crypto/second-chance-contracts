// SPDX-License-Identifier: MIT



pragma solidity ^0.6.0;

interface ISecondChance {
    function swapfor2NDChance(address _ERC20swapped, uint256 _amount) external payable;
    function isAllowed(address _address) external view returns(bool);
}