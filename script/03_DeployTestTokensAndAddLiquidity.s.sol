// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {Constants} from "./base/Constants.sol";
import {TestToken} from "../src/TestToken.sol";

contract DeployTestTokensAndAddLiquidityScript is Script, Constants {
    using CurrencyLibrary for Currency;

    // Our deployed test tokens
    TestToken public token0;
    TestToken public token1;
    Currency public currency0;
    Currency public currency1;
    
    // Hooks contract - empty for our test
    address public hookContract = address(0);

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1e18; // TestUSDC with 18 decimals for simplicity
    uint256 public token1Amount = 1e18; // TestWETH with 18 decimals
    
    // Define a liquidity amount
    uint128 public liquidityAmount = 1e18;

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////

    function run() external {
        console.log("Starting DeployTestTokensAndAddLiquidity script");
        
        vm.startBroadcast();
        
        // Deploy test tokens
        console.log("Deploying test tokens...");
        token0 = new TestToken("Test USDC", "TUSDC", 18);
        token1 = new TestToken("Test WETH", "TWETH", 18);
        
        // Ensure token0 address is less than token1 for Uniswap ordering
        if (address(token0) > address(token1)) {
            // Swap them if needed
            TestToken temp = token0;
            token0 = token1;
            token1 = temp;
        }
        
        console.log("Token0 (TUSDC) deployed at:", address(token0));
        console.log("Token1 (TWETH) deployed at:", address(token1));
        
        // Mint test tokens to ourselves
        console.log("Minting test tokens...");
        token0.mint(msg.sender, token0Amount * 10);
        token1.mint(msg.sender, token1Amount * 10);
        
        console.log("Token0 balance:", token0.balanceOf(msg.sender));
        console.log("Token1 balance:", token1.balanceOf(msg.sender));
        
        // Wrap tokens in Currency
        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));
        
        // Create pool key
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hookContract)
        });
        
        // Initialize pool
        console.log("Initializing pool...");
        uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)
        bytes memory hookData = new bytes(0);
        
        // multicall parameters
        bytes[] memory params = new bytes[](1);
        
        // initialize pool
        params[0] = abi.encodeWithSelector(posm.initializePool.selector, pool, startingPrice, hookData);
        
        // Execute multicall to initialize pool
        console.log("Executing initializePool...");
        posm.multicall(params);
        console.log("Pool initialized successfully");
        
        // Approve tokens for position manager
        console.log("Approving tokens for position manager...");
        token0.approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(address(token0), address(posm), type(uint160).max, type(uint48).max);
        
        token1.approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(address(token1), address(posm), type(uint160).max, type(uint48).max);
        
        // Add liquidity using modifyLiquidities through multicall
        console.log("Adding liquidity...");
        
        // Use helper function to encode mint liquidity parameters
        (bytes memory actions, bytes[] memory mintParams) =
            _mintLiquidityParams(pool, tickLower, tickUpper, liquidityAmount, token0Amount, token1Amount, msg.sender, hookData);

        // Create new multicall parameters
        bytes[] memory liqParams = new bytes[](1);
        
        // Set up the modifyLiquidities call
        liqParams[0] = abi.encodeWithSelector(
            posm.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 60
        );
        
        // Execute multicall to add liquidity
        console.log("Executing modifyLiquidities...");
        posm.multicall(liqParams);
        
        console.log("Liquidity added successfully!");
        console.log("Position manager address:", address(posm));
        
        vm.stopBroadcast();
    }
    
    /// @dev helper function for encoding mint liquidity operation
    function _mintLiquidityParams(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 liquidity,
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
}