// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {UMATimeCard} from "../src/UMATimeCard.sol";

contract DeployUMATimeCard is Script {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");

    function run() external returns (UMATimeCard) {
        vm.startBroadcast(deployerKey);
        UMATimeCard umaTimeCard = new UMATimeCard(
            0x07865c6E87B9F70255377e024ace6630C1Eaa37F,
            0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB
        );
        vm.stopBroadcast();

        return umaTimeCard;
    }
}
