// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SepoliaConfig} from "./base/SepoliaConfig.sol";

contract CheckTokenBalancesScript is Script, SepoliaConfig {
    function run() external view {
        // Address to check balances for
        address account = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        console.log("Checking token balances for address:", account);
        
        // Check USDC balance (token0)
        uint256 usdcBalance = token0.balanceOf(account);
        console.log("USDC (token0) balance:", usdcBalance);
        
        // Check WETH balance (token1)
        uint256 wethBalance = token1.balanceOf(account);
        console.log("WETH (token1) balance:", wethBalance);
        
        // Check ETH balance
        uint256 ethBalance = account.balance;
        console.log("Native ETH balance:", ethBalance);
    }
}