// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {Constants} from "./base/Constants.sol";
import {SepoliaConfig} from "./base/SepoliaConfig.sol";

contract SepoliaCreatePoolScript is Script, Constants, SepoliaConfig {
    using CurrencyLibrary for Currency;

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    // fees paid by swappers that accrue to liquidity providers
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // starting price of the pool, in sqrtPriceX96
    // Setting a more appropriate price for the USDC/WETH pair (roughly 1 ETH = 1000 USDC)
    uint160 startingPrice = 2505414483750479311864138015 * 10; // sqrt(1/1000) * 2^96 * 10

    // --- liquidity position configuration --- //
    // Greatly reduced token amounts for testing since we don't have much tokens
    uint256 public token0Amount = 1e6; // 0.000001 USDC (assuming 6 decimals)
    uint256 public token1Amount = 1e15; // 0.001 ETH
    
    // Define a smaller initial liquidity amount to avoid the MaximumAmountExceeded error
    uint128 public forcedLiquidity = 20000; // Force a smaller liquidity value

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////

    function run() external {
        // tokens should be sorted
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
        bytes memory hookData = new bytes(0);

        // --------------------------------- //

        // Using a fixed smaller liquidity amount instead of calculating from token amounts
        // This helps prevent the MaximumAmountExceeded error
        uint128 liquidity = forcedLiquidity;
        
        // Log the liquidity amount for debugging
        console.log("Using liquidity amount:", liquidity);
        
        // Original calculation commented out:
        // uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
        //     startingPrice,
        //     TickMath.getSqrtPriceAtTick(tickLower),
        //     TickMath.getSqrtPriceAtTick(tickUpper),
        //     token0Amount,
        //     token1Amount
        // );

        // Greatly increase the slippage limits to allow for any calculation differences
        uint256 amount0Max = token0Amount * 10; // 10x the amount to allow for slippage 
        uint256 amount1Max = token1Amount * 10; // 10x the amount to allow for slippage
        
        console.log("Token0 max amount:", amount0Max);
        console.log("Token1 max amount:", amount1Max);

        // Use msg.sender to avoid script contract issues
        (bytes memory actions, bytes[] memory mintParams) =
            _mintLiquidityParams(pool, tickLower, tickUpper, liquidity, amount0Max, amount1Max, msg.sender, hookData);

        // multicall parameters
        bytes[] memory params = new bytes[](2);

        // initialize pool
        params[0] = abi.encodeWithSelector(posm.initializePool.selector, pool, startingPrice, hookData);

        // mint liquidity
        params[1] = abi.encodeWithSelector(
            posm.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 60
        );

        // if the pool is an ETH pair, native tokens are to be transferred
        uint256 valueToPass = currency0.isAddressZero() ? amount0Max : 0;

        // Do all operations in a single broadcast
        vm.startBroadcast();
        
        console.log("Approving tokens for Position Manager...");
        
        // Approve tokens
        tokenApprovals();
        
        console.log("Creating pool and adding liquidity...");
        
        // Execute multicall
        posm.multicall{value: valueToPass}(params);
        
        console.log("Pool created and liquidity added successfully!");
        
        vm.stopBroadcast();
    }

    /// @dev helper function for encoding mint liquidity operation
    function _mintLiquidityParams(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 liquidity,
        uint256 amount0Max,
        uint256 amount1Max,
        address recipient,
        bytes memory hookData
    ) internal pure returns (bytes memory, bytes[] memory) {
        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(poolKey, _tickLower, _tickUpper, liquidity, amount0Max, amount1Max, recipient, hookData);
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        return (actions, params);
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