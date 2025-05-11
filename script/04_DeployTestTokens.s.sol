// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {TestToken} from "../src/TestToken.sol";

contract DeployTestTokensScript is Script {
    TestToken public tusdc;
    TestToken public tweth;

    function run() external {
        console.log("Starting test token deployment");
        
        // Deploy tokens with broadcast to actually deploy them
        vm.startBroadcast();
        
        // Deploy test tokens
        tusdc = new TestToken("Test USDC", "TUSDC", 18);
        tweth = new TestToken("Test WETH", "TWETH", 18);
        
        console.log("TUSDC deployed at:", address(tusdc));
        console.log("TWETH deployed at:", address(tweth));
        
        // Mint tokens to the deployer
        tusdc.mint(msg.sender, 1000 * 1e18);
        tweth.mint(msg.sender, 1000 * 1e18);
        
        console.log("Tokens minted to:", msg.sender);
        console.log("TUSDC balance:", tusdc.balanceOf(msg.sender));
        console.log("TWETH balance:", tweth.balanceOf(msg.sender));
        
        vm.stopBroadcast();
        
        // Verify the tokens were deployed correctly
        console.log("Token deployment completed successfully");
    }
}