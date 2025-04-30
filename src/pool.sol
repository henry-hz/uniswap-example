// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IUnlockCallback} from "v4-core/interfaces/callback/IUnlockCallback.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";

contract UniswapV4Interactor is IUnlockCallback {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    IPoolManager public immutable poolManager;
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    // Constants
    uint24 public constant FEE = 3000;
    int24 public constant TICK_SPACING = 60;

    constructor(address _poolManager, address _tokenA, address _tokenB) {
        poolManager = IPoolManager(_poolManager);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(int24 tickLower, int24 tickUpper, uint128 liquidityAmount) external {
        // Take tokens from the caller
        tokenA.transferFrom(msg.sender, address(this), 1000e18);
        tokenB.transferFrom(msg.sender, address(this), 1000e18);
        
        // Approve maximum amount to the pool manager
        tokenA.approve(address(poolManager), type(uint256).max);
        tokenB.approve(address(poolManager), type(uint256).max);

        // Sort tokens by address to ensure correct order
        (address token0, address token1) = sortTokens(address(tokenA), address(tokenB));
        
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });

        bytes memory callbackData = abi.encode(key, tickLower, tickUpper, liquidityAmount);

        poolManager.unlock(callbackData);
    }
    
    /// @inheritdoc IUnlockCallback
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(poolManager), "Unauthorized");
        
        (PoolKey memory key, int24 tickLower, int24 tickUpper, uint128 liquidityAmount) = 
            abi.decode(data, (PoolKey, int24, int24, uint128));

        // First sync currencies to make sure the pool knows about our tokens
        poolManager.sync(key.currency0);
        poolManager.sync(key.currency1);
        
        // Add liquidity to the pool
        (BalanceDelta delta,) = poolManager.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(uint256(liquidityAmount)),
                salt: bytes32(0)
            }),
            ""
        );
        
        // Now pay what we owe to the pool
        poolManager.settle();
        
        return "";
    }
    
    // Helper function to sort tokens by address
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
