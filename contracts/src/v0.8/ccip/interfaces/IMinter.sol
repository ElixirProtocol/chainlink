// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
  /// @notice Mints new tokens for a given address.
  /// @param account The address to mint the new tokens to.
  /// @param amount The number of tokens to be minted.
  /// @dev this function increases the total supply.
  function mint(address account, uint256 amount) external;
}
