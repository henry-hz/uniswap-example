// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract BasicCheckScript is Script {
    // Addresses from deployment
    address constant TOKEN_A = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant TOKEN_B = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant INTERACTOR = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address constant POOL_MANAGER = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;

    function run() external view {
        // Check code sizes directly
        uint256 sizeA = getCodeSize(TOKEN_A);
        uint256 sizeB = getCodeSize(TOKEN_B);
        uint256 sizeInteractor = getCodeSize(INTERACTOR);
        uint256 sizeManager = getCodeSize(POOL_MANAGER);

        console.log("Code sizes:");
        console.log("Token A:", sizeA);
        console.log("Token B:", sizeB);
        console.log("Interactor:", sizeInteractor);
        console.log("Pool Manager:", sizeManager);
    }

    function getCodeSize(address addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}