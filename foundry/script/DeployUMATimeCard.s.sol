// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {UMATimeCard} from "../src/UMATimeCard.sol";

contract DeployUMATimeCard is Script {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");

    function run() external returns (UMATimeCard) {
        vm.startBroadcast(deployerKey);
        UMATimeCard umaTimeCard = new UMATimeCard(
            0x328507DC29C95c170B56a1b3A758eB7a9E73455c, //currency
            0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB, //optimisticOracleV3
            0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23 //lzEndpoint
        );
        vm.stopBroadcast();

        return umaTimeCard;
    }
}
