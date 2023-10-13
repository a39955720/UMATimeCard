//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {NonblockingLzApp, Ownable} from "@LayerZero/contracts/lzApp/NonblockingLzApp.sol";

contract UMATimeCardEntrance is NonblockingLzApp {
    uint16 immutable i_destChainId;

    constructor(
        uint16 _destChainId,
        address _lzEndpoint
    ) NonblockingLzApp(_lzEndpoint) Ownable() {
        i_destChainId = _destChainId;
    }

    function send(uint16 checkInOrOut) public payable {
        bytes memory payload = abi.encode(
            checkInOrOut,
            block.timestamp,
            msg.sender
        );

        _lzSend(
            i_destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {}

    function estimateFees(
        bytes calldata adapterParams,
        uint16 checkInOrOut
    ) public view returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(
            checkInOrOut,
            block.timestamp,
            msg.sender
        );

        return
            lzEndpoint.estimateFees(
                i_destChainId,
                address(this),
                payload,
                false,
                adapterParams
            );
    }
}
