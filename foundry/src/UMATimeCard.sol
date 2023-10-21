// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ClaimData} from "@protocol/packages/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import {OptimisticOracleV3Interface} from "@protocol/packages/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {NonblockingLzApp, Ownable} from "@LayerZero/contracts/lzApp/NonblockingLzApp.sol";

// Custom error messages
error UMATimeCard__YouShouldCheckInFirst();
error UMATimeCard__YouShouldCheckOutFirst();
error UMATimeCard__YouCantCallThisFunction();

contract UMATimeCard is NonblockingLzApp {
    using SafeERC20 for IERC20;

    // Create an Optimistic Oracle V3 instance at the deployed address on Görli.
    OptimisticOracleV3Interface private immutable i_oov3;

    // Reference to the default currency (ERC20 token)
    IERC20 public immutable i_defaultCurrency;

    // Struct to store check-in/check-out data
    struct CheckInOutData {
        bytes32 assertionId;
        uint256 timestamp;
        bool isDispute;
    }

    address immutable i_lzEndpoint;

    mapping(bytes32 => address) private s_assertionIdToEmployee;

    mapping(address => CheckInOutData[]) private s_checkInData;
    mapping(address => CheckInOutData[]) private s_checkOutData;

    mapping(address => bool) private s_checkInLock;
    mapping(address => bool) private s_checkOutLock;

    constructor(
        address _defaultCurrency,
        address _optimisticOracleV3,
        address _lzEndpoint
    ) NonblockingLzApp(_lzEndpoint) Ownable() {
        i_defaultCurrency = IERC20(_defaultCurrency);
        i_oov3 = OptimisticOracleV3Interface(_optimisticOracleV3);
        i_lzEndpoint = _lzEndpoint;
    }

    // Function to perform check-in
    function checkIn(
        uint256 _timestamp,
        address _msgSender,
        string memory _url
    ) public {
        // Check if the check-in lock is enabled, indicating that check-out should be performed first
        if (s_checkInLock[_msgSender] == true) {
            revert UMATimeCard__YouShouldCheckOutFirst();
        }

        // For test revert
        if (msg.sender != address(this)) {
            revert UMATimeCard__YouCantCallThisFunction();
        }

        uint256 bond = i_oov3.getMinimumBond(address(i_defaultCurrency));
        i_defaultCurrency.safeTransferFrom(msg.sender, address(this), bond);
        i_defaultCurrency.safeApprove(address(i_oov3), bond);

        // If there are previous check-out data for the employee, settle the corresponding assertion
        if (s_checkOutData[_msgSender].length > 0) {
            uint256 index = s_checkOutData[_msgSender].length - 1;
            if (
                s_checkOutData[_msgSender][index].isDispute == false ||
                getCheckInOutResult(
                    s_checkOutData[_msgSender][index].assertionId
                ) ==
                false
            ) {
                i_oov3.settleAndGetAssertionResult(
                    s_checkOutData[_msgSender][index].assertionId
                );
            }
        }

        // Generate the check-in message
        bytes memory checkInMessage = abi.encodePacked(
            "Check in at: ",
            ClaimData.toUtf8BytesUint(_timestamp),
            " ,employee is 0x",
            ClaimData.toUtf8BytesAddress(_msgSender),
            " ,proof of work document link (e.g., GitHub URL): ",
            bytes(_url),
            " ,in the UMATimeCard contract at 0x",
            ClaimData.toUtf8BytesAddress(address(this)),
            " is valid."
        );

        // Create a new assertion for the check-in data
        bytes32 _assertionId = i_oov3.assertTruth(
            checkInMessage,
            address(this),
            address(this),
            address(0),
            180,
            i_defaultCurrency,
            bond,
            i_oov3.defaultIdentifier(),
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
    function checkOut(
        uint256 _timestamp,
        address _msgSender,
        string memory _url
    ) public {
        // Check if the check-out lock is enabled or if there are no previous check-in data
        if (
            s_checkOutLock[_msgSender] == true ||
            s_checkInData[_msgSender].length == 0
        ) {
            revert UMATimeCard__YouShouldCheckInFirst();
        }

        // For test revert
        if (msg.sender != address(this)) {
            revert UMATimeCard__YouCantCallThisFunction();
        }

        uint256 bond = i_oov3.getMinimumBond(address(i_defaultCurrency));
        i_defaultCurrency.safeTransferFrom(msg.sender, address(this), bond);
        i_defaultCurrency.safeApprove(address(i_oov3), bond);

        // If there are previous check-in data for the employee, settle the corresponding assertion
        uint256 index = s_checkInData[_msgSender].length - 1;
        if (
            s_checkInData[_msgSender][index].isDispute == false ||
            getCheckInOutResult(s_checkInData[_msgSender][index].assertionId) ==
            false
        ) {
            i_oov3.settleAndGetAssertionResult(
                s_checkInData[_msgSender][index].assertionId
            );
        }

        // Generate the check-out message
        bytes memory checkOutMessage = abi.encodePacked(
            "Check out at: ",
            ClaimData.toUtf8BytesUint(_timestamp),
            " ,employee is 0x",
            ClaimData.toUtf8BytesAddress(_msgSender),
            " ,proof of work document link (e.g., GitHub URL): ",
            bytes(_url),
            " ,in the UMATimeCard contract at 0x",
            ClaimData.toUtf8BytesAddress(address(this)),
            " is valid."
        );

        // Create a new assertion for the check-out data
        bytes32 _assertionId = i_oov3.assertTruth(
            checkOutMessage,
            address(this),
            address(this),
            address(0),
            180,
            i_defaultCurrency,
            bond,
            i_oov3.defaultIdentifier(),
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
        require(msg.sender == address(i_oov3));

        // Get the employee associated with the disputed assertionId
        address employee = s_assertionIdToEmployee[assertionId];

        if (!assertedTruthfully) {
            if (s_checkInLock[employee] == true) {
                // If the check-in lock is enabled, mark the corresponding check-in data as disputed
                uint256 index = s_checkInData[employee].length - 1;
                s_checkInData[employee][index].timestamp = 0;
            } else {
                // If the check-out lock is enabled, mark the corresponding check-out data as disputed
                uint256 index = s_checkOutData[employee].length - 1;
                s_checkOutData[employee][index].timestamp = 0;
            }
        }
    }

    // Callback function called when an assertion is disputed
    function assertionDisputedCallback(bytes32 assertionId) public {
        require(msg.sender == address(i_oov3));

        // Get the employee associated with the disputed assertionId
        address employee = s_assertionIdToEmployee[assertionId];

        if (s_checkInLock[employee] == true) {
            // If the check-in lock is enabled, mark the corresponding check-in data as disputed
            uint256 index = s_checkInData[employee].length - 1;
            s_checkInData[employee][index].isDispute = true;
        } else {
            // If the check-out lock is enabled, mark the corresponding check-out data as disputed
            uint256 index = s_checkOutData[employee].length - 1;
            s_checkOutData[employee][index].isDispute = true;
        }
    }

    // This function handles the received payload from LayerZero and triggers the appropriate check-in or check-out function based on the message type.
    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        (
            uint16 _message1,
            uint256 _message2,
            address _message3,
            string memory _message4
        ) = abi.decode(_payload, (uint16, uint256, address, string));

        if (_message1 == 0) {
            checkIn(_message2, _message3, _message4);
        } else if (_message1 == 1) {
            checkOut(_message2, _message3, _message4);
        }
    }

    ////////////////////////////
    ////////Get Function///////
    //////////////////////////

    function getCheckInOutResult(
        bytes32 _assertionId
    ) public view returns (bool) {
        return i_oov3.getAssertionResult(_assertionId);
    }

    function getCheckInData(
        address employee
    ) public view returns (CheckInOutData[] memory) {
        return s_checkInData[employee];
    }

    function getCheckOutData(
        address employee
    ) public view returns (CheckInOutData[] memory) {
        return s_checkOutData[employee];
    }
}
