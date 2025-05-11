// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {TestToken} from "../src/TestToken.sol";
import {Constants} from "./base/Constants.sol";

contract CreatePoolWithDeployedTokens is Script, Constants {
    using CurrencyLibrary for Currency;
    
    // Replace these with the addresses of the deployed test tokens
    address public tusdc = 0xEA79E63A19fcae4Fe7986A34E1464178890163ee;
    address public tweth = 0x82c821E48092A78CB61393eDeE33d8a783875730;
    
    // Set up as Currency objects
    Currency public currency0;
    Currency public currency1;
    
    // Hooks contract - empty for our test
    address public hookContract = address(0);

    // Pool configuration
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    function run() external {
        console.log("Starting CreatePoolWithDeployedTokens script");
        
        // Ensure the token with smaller address is currency0
        if (tusdc < tweth) {
            currency0 = Currency.wrap(tusdc);
            currency1 = Currency.wrap(tweth);
            console.log("TUSDC is currency0, TWETH is currency1");
        } else {
            currency0 = Currency.wrap(tweth);
            currency1 = Currency.wrap(tusdc);
            console.log("TWETH is currency0, TUSDC is currency1");
        }
        
        // Create pool key
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hookContract)
        });
        
        console.log("Pool currencies:");
        console.log("currency0:", address(currency0));
        console.log("currency1:", address(currency1));
        
        // Initialize pool
        console.log("Initializing pool...");
        uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)
        bytes memory hookData = new bytes(0);
        
        // Create multicall parameters
        bytes[] memory params = new bytes[](1);
        
        // Initialize pool
        params[0] = abi.encodeWithSelector(posm.initializePool.selector, pool, startingPrice, hookData);
        
        // Execute pool initialization
        vm.startBroadcast();
        
        console.log("Executing initializePool via multicall...");
        posm.multicall(params);
        
        console.log("Pool initialized successfully!");
        console.log("Position manager address:", address(posm));
        
        vm.stopBroadcast();
    }
}