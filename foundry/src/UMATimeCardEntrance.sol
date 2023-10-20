//SPDX-License-Identifier: MIT
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

    /**
     * @dev Sends time card check-in/out information to the destination chain.
     *
     * @param checkInOrOut The type of check-in/out, 0 for check-in, 1 for check-out.
     */
    function send(uint16 checkInOrOut, string memory _url) public payable {
        bytes memory payload = abi.encode(
            checkInOrOut,
            block.timestamp,
            msg.sender,
            _url
        );

        _lzSend(
            i_destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            abi.encodePacked(uint16(1), uint(800000)),
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {}

    // Estimates the fees required to send a time card transaction.
    function estimateFees(
        bytes calldata adapterParams,
        uint16 checkInOrOut,
        string memory url
    ) public view returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(
            checkInOrOut,
            block.timestamp,
            msg.sender,
            url
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
