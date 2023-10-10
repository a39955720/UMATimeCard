// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@protocol/packages/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@protocol/packages/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

// Custom error messages
error UMATimeCard__YouShouldCheckInFirst();
error UMATimeCard__YouShouldCheckOutFirst();

contract UMATimeCard {
    // Create an Optimistic Oracle V3 instance at the deployed address on Görli.
    OptimisticOracleV3Interface private constant OOV3 =
        OptimisticOracleV3Interface(0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB);

    // Reference to the default currency (ERC20 token)
    IERC20 public constant DEFAULTCURRENCY =
        IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);

    // Struct to store check-in/check-out data
    struct CheckInOutData {
        bytes32 assertionId;
        uint256 timestamp;
        bool isDispute;
    }

    mapping(bytes32 => address) private s_assertionIdToEmployee;

    mapping(address => CheckInOutData[]) private s_checkInData;
    mapping(address => CheckInOutData[]) private s_checkOutData;

    mapping(address => bool) private s_checkInLock;
    mapping(address => bool) private s_checkOutLock;

    // Function to perform check-in
    function checkIn(uint256 _timestamp, address _msgSender) public {
        // Check if the check-in lock is enabled, indicating that check-out should be performed first
        if (s_checkInLock[_msgSender] == true) {
            revert UMATimeCard__YouShouldCheckOutFirst();
        }

        // If there are previous check-out data for the employee, settle the corresponding assertion
        if (s_checkOutData[_msgSender].length > 0) {
            uint256 index = s_checkOutData[_msgSender].length - 1;
            if (s_checkOutData[_msgSender][index].isDispute == false) {
                OOV3.settleAndGetAssertionResult(
                    s_checkOutData[_msgSender][index].assertionId
                );
            }
        }

        // Generate the check-in message
        bytes memory checkInMessage = abi.encodePacked(
            "Check in at: ",
            ClaimData.toUtf8BytesUint(_timestamp),
            " employee is 0x",
            ClaimData.toUtf8BytesAddress(_msgSender),
            " in the UMATimeCard contract at 0x",
            ClaimData.toUtf8BytesAddress(address(this)),
            " is valid."
        );

        // Create a new assertion for the check-in data
        bytes32 _assertionId = OOV3.assertTruth(
            checkInMessage,
            address(this),
            address(this),
            address(0),
            120,
            DEFAULTCURRENCY,
            0,
            OOV3.defaultIdentifier(),
            bytes32(0)
        );

        // Store the check-in data and associate it with the employee
        s_checkInData[_msgSender].push(
            CheckInOutData(_assertionId, _timestamp, false)
        );
        s_assertionIdToEmployee[_assertionId] = _msgSender;

        // Set the check-in lock and disable the check-out lock
        s_checkInLock[_msgSender] = true;
        s_checkOutLock[_msgSender] = false;
    }

    // Function to perform check-out
    function checkOut(uint256 _timestamp, address _msgSender) public {
        // Check if the check-out lock is enabled or if there are no previous check-in data
        if (
            s_checkOutLock[_msgSender] == true ||
            s_checkInData[_msgSender].length == 0
        ) {
            revert UMATimeCard__YouShouldCheckInFirst();
        }

        // If there are previous check-in data for the employee, settle the corresponding assertion
        uint256 index = s_checkInData[_msgSender].length - 1;
        if (s_checkInData[_msgSender][index].isDispute == false) {
            OOV3.settleAndGetAssertionResult(
                s_checkInData[_msgSender][index].assertionId
            );
        }

        // Generate the check-out message
        bytes memory checkOutMessage = abi.encodePacked(
            "Check out at: ",
            ClaimData.toUtf8BytesUint(_timestamp),
            " employee is 0x",
            ClaimData.toUtf8BytesAddress(_msgSender),
            " in the UMATimeCard contract at 0x",
            ClaimData.toUtf8BytesAddress(address(this)),
            " is valid."
        );

        // Create a new assertion for the check-out data
        bytes32 _assertionId = OOV3.assertTruth(
            checkOutMessage,
            address(this),
            address(this),
            address(0),
            120,
            DEFAULTCURRENCY,
            0,
            OOV3.defaultIdentifier(),
            bytes32(0)
        );

        // Store the check-out data and associate it with the employee
        s_checkOutData[_msgSender].push(
            CheckInOutData(_assertionId, _timestamp, false)
        );
        s_assertionIdToEmployee[_assertionId] = _msgSender;

        // Set the check-out lock and disable the check-in lock
        s_checkOutLock[_msgSender] = true;
        s_checkInLock[_msgSender] = false;
    }

    // Callback function called when an assertion is resolved
    function assertionResolvedCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) public {
        require(msg.sender == address(OOV3));
    }

    // Callback function called when an assertion is disputed
    function assertionDisputedCallback(bytes32 assertionId) public {
        require(msg.sender == address(OOV3));

        // Get the employee associated with the disputed assertionId
        address employee = s_assertionIdToEmployee[assertionId];

        if (s_checkInLock[employee] == true) {
            // If the check-in lock is enabled, mark the corresponding check-in data as disputed
            uint256 index = s_checkInData[employee].length - 1;
            s_checkInData[employee][index].timestamp = 0;
            s_checkInData[employee][index].isDispute = true;
        } else {
            // If the check-out lock is enabled, mark the corresponding check-out data as disputed
            uint256 index = s_checkOutData[employee].length - 1;
            s_checkOutData[employee][index].timestamp = 0;
            s_checkOutData[employee][index].isDispute = true;
        }
    }

    ////////////////////////////
    ////////Get Function///////
    //////////////////////////

    function getCheckInOutResult(
        bytes32 _assertionId
    ) public view returns (bool) {
        return OOV3.getAssertionResult(_assertionId);
    }

    function getCheckInData() public view returns (CheckInOutData[] memory) {
        return s_checkInData[msg.sender];
    }

    function getCheckOutData() public view returns (CheckInOutData[] memory) {
        return s_checkOutData[msg.sender];
    }
}
