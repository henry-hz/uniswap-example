// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

contract UniswapV4Interactor {
    using PoolIdLibrary for PoolKey;

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
        tokenA.transferFrom(msg.sender, address(this), 1000e18);
        tokenA.approve(address(poolManager), 1000e18);

        tokenB.transferFrom(msg.sender, address(this), 1000e18);
        tokenB.approve(address(poolManager), 1000e18);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });

        bytes memory callbackData = abi.encode(key, tickLower, tickUpper, liquidityAmount);

        poolManager.unlock(
            abi.encodeWithSelector(
                this.lockAcquired.selector,
                callbackData
            )
        );
    }

    function lockAcquired(bytes calldata data) external {
        require(msg.sender == address(poolManager), "Unauthorized");

        (PoolKey memory key, int24 tickLower, int24 tickUpper, uint128 liquidityAmount) = 
            abi.decode(data, (PoolKey, int24, int24, uint128));

        poolManager.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(uint256(liquidityAmount)),
                salt: bytes32(0)
            }),
            ""
        );
    }
}
