// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {EasyPosm} from "../test/utils/EasyPosm.sol";
import {Constants} from "./base/Constants.sol";
import {SepoliaConfig} from "./base/SepoliaConfig.sol";

contract SepoliaAddLiquidityScript is Script, Constants, SepoliaConfig {
    using CurrencyLibrary for Currency;
    using EasyPosm for IPositionManager;
    using StateLibrary for IPoolManager;

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    // fees paid by swappers that accrue to liquidity providers
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // --- liquidity position configuration --- //
    // Use minimal amounts for testing
    uint256 public token0Amount = 1e6; // 0.000001 USDC (assuming 6 decimals)
    uint256 public token1Amount = 1e15; // 0.001 ETH
    
    // Define a smaller liquidity amount to avoid transfer errors
    uint128 public forcedLiquidity = 10000; // Force a small liquidity value

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////

    function run() external {
        console.log("Starting SepoliaAddLiquidity script");
        console.log("Configured token0 (USDC) amount:", token0Amount);
        console.log("Configured token1 (WETH) amount:", token1Amount);
        
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        console.log("Checking pool state...");
        (uint160 sqrtPriceX96,,,) = POOLMANAGER.getSlot0(pool.toId());
        console.log("Current pool price:", uint256(sqrtPriceX96));

        // Use our fixed small liquidity amount
        uint128 liquidity = forcedLiquidity;
        console.log("Using liquidity amount:", liquidity);

        // Increase slippage limits to prevent MaximumAmountExceeded errors
        uint256 amount0Max = token0Amount * 10;
        uint256 amount1Max = token1Amount * 10;
        console.log("Token0 max amount:", amount0Max);
        console.log("Token1 max amount:", amount1Max);

        bytes memory hookData = new bytes(0);

        console.log("Approving tokens for position manager...");
        vm.startBroadcast();
        
        tokenApprovals();
        
        console.log("Adding liquidity...");
        // Use token amounts that are even smaller for the actual transaction since we don't have tokens
        IPositionManager(address(posm)).mint(
            pool, 
            tickLower, 
            tickUpper, 
            liquidity, 
            amount0Max, 
            amount1Max, 
            msg.sender, 
            block.timestamp + 60, 
            hookData
        );
        console.log("Liquidity added successfully!");
        
        vm.stopBroadcast();
    }

    function tokenApprovals() public {
        console.log("Token0 address:", address(token0));
        console.log("Token1 address:", address(token1));
        console.log("PERMIT2 address:", address(PERMIT2));
        console.log("Position Manager address:", address(posm));
        
        if (!currency0.isAddressZero()) {
            token0.approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(address(token0), address(posm), type(uint160).max, type(uint48).max);
        }
        if (!currency1.isAddressZero()) {
            token1.approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(address(token1), address(posm), type(uint160).max, type(uint48).max);
        }
    }
}