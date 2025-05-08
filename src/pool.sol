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

        // Create the pool key with sorted tokens
        PoolKey memory key = createPoolKey();

        bytes memory callbackData = abi.encode(key, tickLower, tickUpper, liquidityAmount);
        poolManager.unlock(callbackData);
    }

    /// @inheritdoc IUnlockCallback
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(poolManager), "Unauthorized");

        (PoolKey memory key, int24 tickLower, int24 tickUpper, uint128 liquidityAmount) =
            abi.decode(data, (PoolKey, int24, int24, uint128));

        // Add liquidity to the pool and get the delta (how many tokens we need to provide)
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

        // Handle both token settlements with a helper function
        handleTokenSettlement(key.currency0, delta.amount0());
        handleTokenSettlement(key.currency1, delta.amount1());

        return "";
    }

    // Helper function to create a pool key with sorted tokens
    function createPoolKey() internal view returns (PoolKey memory) {
        (address token0, address token1) = sortTokens(address(tokenA), address(tokenB));

        return PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
    }

    // Helper function to handle token settlement
    function handleTokenSettlement(Currency currency, int128 amount) internal {
        if (amount < 0) {
            // First sync the currency
            poolManager.sync(currency);

            // Get token address and transfer tokens to the pool
            address token = Currency.unwrap(currency);
            uint256 amountNeeded = uint256(uint128(-amount));
            IERC20(token).transfer(address(poolManager), amountNeeded);

            // Now settle with the pool
            poolManager.settle();
        }
    }

    // Helper function to sort tokens by address
    function sortTokens(address token0, address token1) internal pure returns (address, address) {
        return token0 < token1 ? (token0, token1) : (token1, token0);
    }
}
