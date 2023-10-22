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
     * @dev Sends time card check-in information to the destination chain.
     *
     * @param _url proof of work document link (e.g., GitHub URL).
     */
    function checkIn(string memory _url) public payable {
        bytes memory payload = abi.encode(0, block.timestamp, msg.sender, _url);

        _lzSend(
            i_destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            abi.encodePacked(uint16(1), uint(800000)),
            msg.value
        );
    }

    /**
     * @dev Sends time card check-out information to the destination chain.
     *
     * @param _url proof of work document link (e.g., GitHub URL).
     */
    function checkOut(string memory _url) public payable {
        bytes memory payload = abi.encode(1, block.timestamp, msg.sender, _url);

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
        string memory url
    ) public view returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(1, block.timestamp, msg.sender, url);
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
