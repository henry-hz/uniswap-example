// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV4Interactor} from "../src/pool.sol";
import {Token} from "../src/token.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {LiquidityAmounts} from "test-utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

contract UniswapV4InteractorTest is Test {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PoolManager public poolManager;
    Token public tokenA;
    Token public tokenB;
    UniswapV4Interactor public interactor;

    // Constants
    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 1:1 price
    uint24 public constant FEE = 3000;
    int24 public constant TICK_SPACING = 60;
    int24 public constant TICK_LOWER = -120;
    int24 public constant TICK_UPPER = 120;
    uint128 public constant LIQUIDITY_AMOUNT = 1000e18;

    function setUp() public {
        // Deploy tokens
        tokenA = new Token("Token A", "TKNA", 1000000e18);
        tokenB = new Token("Token B", "TKNB", 1000000e18);
        
        // Deploy the pool manager
        poolManager = new PoolManager(500000);
        
        // Deploy the interactor
        interactor = new UniswapV4Interactor(
            address(poolManager),
            address(tokenA),
            address(tokenB)
        );
        
        // Transfer tokens to the test contract for testing
        tokenA.transfer(address(this), 10000e18);
        tokenB.transfer(address(this), 10000e18);
        
        // Transfer tokens to the interactor for adding liquidity
        tokenA.transfer(address(interactor), 2000e18);
        tokenB.transfer(address(interactor), 2000e18);
    }

    function test_Initialize() public {
        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
        
        // Initialize the pool
        vm.startPrank(address(interactor));
        tokenA.approve(address(poolManager), type(uint256).max);
        tokenB.approve(address(poolManager), type(uint256).max);
        
        int24 tick = poolManager.initialize(key, SQRT_PRICE_1_1);
        vm.stopPrank();
        
        // Verify pool was initialized
        assertEq(tick, 0, "Pool should initialize at tick 0");
    }

    function test_AddLiquidity() public {
        // Initialize the pool first
        test_Initialize();
        
        // Initial balances
        uint256 initialTokenABalance = tokenA.balanceOf(address(this));
        uint256 initialTokenBBalance = tokenB.balanceOf(address(this));
        
        // Prepare to add liquidity
        vm.startPrank(address(this));
        tokenA.approve(address(interactor), 1000e18);
        tokenB.approve(address(interactor), 1000e18);
        
        // Add liquidity through the interactor
        interactor.addLiquidity(TICK_LOWER, TICK_UPPER, LIQUIDITY_AMOUNT);
        vm.stopPrank();
        
        // Verify tokens were transferred
        uint256 finalTokenABalance = tokenA.balanceOf(address(this));
        uint256 finalTokenBBalance = tokenB.balanceOf(address(this));
        
        assertEq(initialTokenABalance - finalTokenABalance, 1000e18, "Token A should be transferred");
        assertEq(initialTokenBBalance - finalTokenBBalance, 1000e18, "Token B should be transferred");
        
        // Create pool key to query position
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
        
        // We can't easily query the position directly, but we can check that tokens were transferred
        // to the pool manager through the balances
        uint256 poolManagerTokenA = tokenA.balanceOf(address(poolManager));
        uint256 poolManagerTokenB = tokenB.balanceOf(address(poolManager));
        
        assertGt(poolManagerTokenA, 0, "Pool manager should have Token A");
        assertGt(poolManagerTokenB, 0, "Pool manager should have Token B");
    }
    
    function test_AddLiquidityWithParameters() public {
        // Initialize the pool first
        test_Initialize();
        
        // Calculate liquidity from token amounts
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            SQRT_PRICE_1_1, 
            TickMath.getSqrtPriceAtTick(TICK_LOWER),
            TickMath.getSqrtPriceAtTick(TICK_UPPER),
            1000e18,
            1000e18
        );
        
        // Prepare to add liquidity
        vm.startPrank(address(this));
        tokenA.approve(address(interactor), 1000e18);
        tokenB.approve(address(interactor), 1000e18);
        
        // Add liquidity with specific parameters
        interactor.addLiquidity(TICK_LOWER, TICK_UPPER, liquidity);
        vm.stopPrank();
        
        // Create pool key to check results
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
        
        // Verify tokens were transferred to the pool manager
        uint256 poolManagerTokenA = tokenA.balanceOf(address(poolManager));
        uint256 poolManagerTokenB = tokenB.balanceOf(address(poolManager));
        
        assertGt(poolManagerTokenA, 0, "Pool manager should have Token A");
        assertGt(poolManagerTokenB, 0, "Pool manager should have Token B");
    }
}