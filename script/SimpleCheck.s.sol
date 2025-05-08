// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Token} from "../src/token.sol";

contract SimpleCheckScript is Script {
    address public TOKEN_A = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public TOKEN_B = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address public INTERACTOR = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address public POOL_MANAGER = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    address public DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() public view {
        // Check if contracts are deployed
        console.log("Code size at Token A:", _getCodeSize(TOKEN_A));
        console.log("Code size at Token B:", _getCodeSize(TOKEN_B));
        console.log("Code size at Interactor:", _getCodeSize(INTERACTOR));
        console.log("Code size at Pool Manager:", _getCodeSize(POOL_MANAGER));
        
        // Check token balances
        uint256 balanceA = IERC20(TOKEN_A).balanceOf(DEPLOYER);
        uint256 balanceB = IERC20(TOKEN_B).balanceOf(DEPLOYER);
        console.log("Token A balance (deployer):", balanceA / 1e18);
        console.log("Token B balance (deployer):", balanceB / 1e18);
        
        // Check interactor balances
        uint256 interactorBalanceA = IERC20(TOKEN_A).balanceOf(INTERACTOR);
        uint256 interactorBalanceB = IERC20(TOKEN_B).balanceOf(INTERACTOR);
        console.log("Token A balance (interactor):", interactorBalanceA / 1e18);
        console.log("Token B balance (interactor):", interactorBalanceB / 1e18);
        
        // Check pool manager balances
        uint256 poolManagerBalanceA = IERC20(TOKEN_A).balanceOf(POOL_MANAGER);
        uint256 poolManagerBalanceB = IERC20(TOKEN_B).balanceOf(POOL_MANAGER);
        console.log("Token A balance (pool manager):", poolManagerBalanceA / 1e18);
        console.log("Token B balance (pool manager):", poolManagerBalanceB / 1e18);
    }
    
    function _getCodeSize(address addr) internal view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size;
    }
}