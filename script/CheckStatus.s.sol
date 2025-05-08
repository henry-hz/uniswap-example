// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV4Interactor} from "../src/pool.sol";
import {Token} from "../src/token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract CheckStatusScript is Script {
    // Address constants - fill these in before running after deployment
    address public tokenA;
    address public tokenB;
    address public interactor;
    address public poolManager;

    function setUp() public {
        // Get these addresses from the Deploy.s.sol output
        tokenA = vm.envOr("TOKEN_A", address(0));
        tokenB = vm.envOr("TOKEN_B", address(0));
        interactor = vm.envOr("INTERACTOR", address(0));
        
        console.log("Using addresses:");
        console.log("Token A:", tokenA);
        console.log("Token B:", tokenB);
        console.log("Interactor:", interactor);
        
        require(tokenA != address(0), "TOKEN_A address not set");
        require(tokenB != address(0), "TOKEN_B address not set");
        require(interactor != address(0), "INTERACTOR address not set");
        
        // Get pool manager by trying a direct call (wrap in try-catch)
        try UniswapV4Interactor(interactor).poolManager() returns (IPoolManager manager) {
            poolManager = address(manager);
            console.log("Pool Manager:", poolManager);
        } catch {
            console.log("Failed to get pool manager, using default address");
            poolManager = 0x34A1D3fff3958843C43aD80F30b94c510645C316; // From deployment logs
        }
    }

    function run() public view {
        // Check token balances
        uint256 tokenADeployer = IERC20(tokenA).balanceOf(msg.sender);
        uint256 tokenBDeployer = IERC20(tokenB).balanceOf(msg.sender);
        
        uint256 tokenAInteractor = IERC20(tokenA).balanceOf(interactor);
        uint256 tokenBInteractor = IERC20(tokenB).balanceOf(interactor);
        
        uint256 tokenAPoolManager = IERC20(tokenA).balanceOf(poolManager);
        uint256 tokenBPoolManager = IERC20(tokenB).balanceOf(poolManager);
        
        console.log("Token A balance (deployer):", tokenADeployer / 1e18);
        console.log("Token B balance (deployer):", tokenBDeployer / 1e18);
        console.log("Token A balance (interactor):", tokenAInteractor / 1e18);
        console.log("Token B balance (interactor):", tokenBInteractor / 1e18);
        console.log("Token A balance (poolManager):", tokenAPoolManager / 1e18);
        console.log("Token B balance (poolManager):", tokenBPoolManager / 1e18);
        
        // Log contract addresses
        console.log("Contract Addresses:");
        console.log("Token A:", tokenA);
        console.log("Token B:", tokenB);
        console.log("Interactor:", interactor);
        console.log("Pool Manager:", poolManager);
    }
}