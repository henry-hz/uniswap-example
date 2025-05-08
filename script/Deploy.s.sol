// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV4Interactor} from "../src/pool.sol";
import {Token} from "../src/token.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

contract DeployScript is Script {
    using CurrencyLibrary for Currency;

    // Constants
    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 1:1 price
    uint24 public constant FEE = 3000;
    int24 public constant TICK_SPACING = 60;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy tokens
        Token tokenA = new Token("TokenA", "TKNA", 1_000_000 * 1e18);
        Token tokenB = new Token("TokenB", "TKNB", 1_000_000 * 1e18);
        
        console.log("Token A deployed at:", address(tokenA));
        console.log("Token B deployed at:", address(tokenB));

        // Deploy pool manager
        PoolManager poolManager = new PoolManager(msg.sender);
        console.log("PoolManager deployed at:", address(poolManager));

        // Deploy interactor
        UniswapV4Interactor interactor = new UniswapV4Interactor(
            address(poolManager),
            address(tokenA),
            address(tokenB)
        );
        console.log("UniswapV4Interactor deployed at:", address(interactor));

        // Initialize a pool with the tokens
        (address token0, address token1) = sortTokens(address(tokenA), address(tokenB));
        
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });

        // Transfer some tokens to the deployer for initial liquidity
        tokenA.transfer(msg.sender, 10_000 * 1e18);
        tokenB.transfer(msg.sender, 10_000 * 1e18);

        // Give some tokens to the interactor contract for testing
        tokenA.transfer(address(interactor), 2_000 * 1e18);
        tokenB.transfer(address(interactor), 2_000 * 1e18);
        
        // Initialize the pool
        int24 tick = poolManager.initialize(key, SQRT_PRICE_1_1);
        console.log("Pool initialized at tick:", uint256(uint24(tick)));

        vm.stopBroadcast();
    }
    
    // Helper function to sort tokens by address
    function sortTokens(address token0, address token1) internal pure returns (address, address) {
        return token0 < token1 ? (token0, token1) : (token1, token0);
    }
}
