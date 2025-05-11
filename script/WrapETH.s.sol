// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IWETH9} from "v4-periphery/src/interfaces/external/IWETH9.sol";
import {SepoliaConfig} from "./base/SepoliaConfig.sol";

contract WrapETHScript is Script, SepoliaConfig {
    function run() external {
        // Get WETH contract
        IWETH9 weth = IWETH9(address(token1));

        // Amount to wrap (0.01 ETH)
        uint256 amountToWrap = 1e16;
        
        console.log("Wrapping ETH to WETH...");
        console.log("WETH address:", address(weth));
        console.log("Amount to wrap:", amountToWrap);
        
        vm.startBroadcast();
        
        // Wrap ETH by sending ETH to the WETH contract
        weth.deposit{value: amountToWrap}();
        
        // Check the new balance
        uint256 newBalance = weth.balanceOf(msg.sender);
        console.log("New WETH balance:", newBalance);
        
        vm.stopBroadcast();
    }
}