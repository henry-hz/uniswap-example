// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

/// @notice Sepolia-specific configuration
contract SepoliaConfig {
    // In Uniswap V4, tokens need to be sorted by address (lower address first)
    // Sepolia USDC (has lower address than WETH)
    IERC20 constant token0 = IERC20(address(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238));
    
    // Sepolia WETH
    IERC20 constant token1 = IERC20(address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9));
    
    // No hook for this example
    IHooks constant hookContract = IHooks(address(0x0));

    // Wrap tokens in Currency type
    Currency constant currency0 = Currency.wrap(address(token0));
    Currency constant currency1 = Currency.wrap(address(token1));
}