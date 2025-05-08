// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV4Interactor} from "../src/pool.sol";
import {Token} from "../src/token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddLiquidityScript is Script {
    // Address constants - fill these in before running after deployment
    address public tokenA;
    address public tokenB;
    address public interactor;
    
    // Liquidity parameters
    int24 public constant TICK_LOWER = -120;
    int24 public constant TICK_UPPER = 120;
    uint128 public constant LIQUIDITY_AMOUNT = 1000e18;

    function setUp() public {
        // Get these addresses from the Deploy.s.sol output
        tokenA = vm.envOr("TOKEN_A", address(0));
        tokenB = vm.envOr("TOKEN_B", address(0));
        interactor = vm.envOr("INTERACTOR", address(0));
        
        require(tokenA != address(0), "TOKEN_A address not set");
        require(tokenB != address(0), "TOKEN_B address not set");
        require(interactor != address(0), "INTERACTOR address not set");
    }

    function run() public {
        vm.startBroadcast();

        // Approve tokens for interactor
        IERC20(tokenA).approve(interactor, 1000e18);
        IERC20(tokenB).approve(interactor, 1000e18);
        
        console.log("Approved tokens for interactor");
        
        // Add liquidity through the interactor
        UniswapV4Interactor(interactor).addLiquidity(TICK_LOWER, TICK_UPPER, LIQUIDITY_AMOUNT);
        
        console.log("Added liquidity to the pool");
        
        // Check balances of tokens
        uint256 balanceA = IERC20(tokenA).balanceOf(msg.sender);
        uint256 balanceB = IERC20(tokenB).balanceOf(msg.sender);
        
        console.log("Current TokenA balance:", balanceA / 1e18);
        console.log("Current TokenB balance:", balanceB / 1e18);

        vm.stopBroadcast();
    }
}