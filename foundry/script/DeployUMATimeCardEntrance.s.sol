// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {UMATimeCardEntrance} from "../src/UMATimeCardEntrance.sol";

contract DeployUMATimeCardEntrance is Script {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    UMATimeCardEntrance umaTimeCardEntrance;

    function run() external returns (UMATimeCardEntrance) {
        vm.startBroadcast(deployerKey);
        if (block.chainid == 5001) {
            umaTimeCardEntrance = new UMATimeCardEntrance(
                10121,
                0x2cA20802fd1Fd9649bA8Aa7E50F0C82b479f35fe
            );
        } else if (block.chainid == 534351) {
            umaTimeCardEntrance = new UMATimeCardEntrance(
                10121,
                0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3
            );
        }
        vm.stopBroadcast();
        return umaTimeCardEntrance;
    }
}
