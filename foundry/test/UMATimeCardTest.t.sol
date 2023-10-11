// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import {CommonOptimisticOracleV3Test} from "@protocol/packages/core/test/foundry/optimistic-oracle-v3/CommonOptimisticOracleV3Test.sol";
import {TestAddress} from "@protocol/packages/core/test/foundry/fixtures/common/TestAddress.sol";
import {DeployUMATimeCard} from "../script/DeployUMATimeCard.s.sol";
import {UMATimeCard} from "../src/UMATimeCard.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract UMATimeCardTest is CommonOptimisticOracleV3Test {
    UMATimeCard umaTimeCard;

    function setUp() public {
        _commonSetup();
        umaTimeCard = new UMATimeCard(
            address(defaultCurrency),
            address(optimisticOracleV3)
        );
    }

    function testLock() public {
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency)) * 2
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency)) * 2
        );
        bytes memory customError = abi.encodeWithSignature(
            "UMATimeCard__YouShouldCheckInFirst()"
        );
        vm.expectRevert(customError);
        umaTimeCard.checkOut(block.timestamp, TestAddress.account1);

        umaTimeCard.checkIn(block.timestamp, TestAddress.account1);

        customError = abi.encodeWithSignature(
            "UMATimeCard__YouShouldCheckOutFirst()"
        );
        vm.expectRevert(customError);
        umaTimeCard.checkIn(block.timestamp, TestAddress.account1);
    }

    function test_CheckInOutNoDispute() public {
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1);

        assertFalse(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].isDispute
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            blocktimestamp
        );

        timer.setCurrentTime(timer.getCurrentTime() + 120);

        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        umaTimeCard.checkOut(block.timestamp, TestAddress.account1);

        assertFalse(
            umaTimeCard.getCheckOutData(TestAddress.account1)[0].isDispute
        );
        assertTrue(
            umaTimeCard.getCheckInOutResult(
                umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId
            )
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            blocktimestamp
        );
        vm.stopPrank();
    }

    function test_CheckInOrOutWithWrongDispute() public {
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1);
        vm.stopPrank();

        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId,
            defaultBond
        );
        _mockOracleResolved(address(mockOracle), oracleRequest, true);

        assertTrue(
            optimisticOracleV3.settleAndGetAssertionResult(
                umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId
            )
        );

        assertTrue(
            umaTimeCard.getCheckInOutResult(
                umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId
            )
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            blocktimestamp
        );
    }

    function test_CheckInOutWithCorrectDispute() public {
        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1);
        vm.stopPrank();

        OracleRequest memory oracleRequest = _disputeAndGetOracleRequest(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId,
            defaultBond
        );
        _mockOracleResolved(address(mockOracle), oracleRequest, false);

        assertFalse(
            optimisticOracleV3.settleAndGetAssertionResult(
                umaTimeCard.getCheckInData(TestAddress.account1)[0].assertionId
            )
        );
        assertTrue(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].isDispute
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            0
        );

        // Increase time in the evm
        vm.warp(block.timestamp + 1);

        vm.startPrank(TestAddress.account1);
        defaultCurrency.allocateTo(
            TestAddress.account1,
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency))
        );

        blocktimestamp = block.timestamp;
        umaTimeCard.checkOut(blocktimestamp, TestAddress.account1);
        vm.stopPrank();

        oracleRequest = _disputeAndGetOracleRequest(
            umaTimeCard.getCheckOutData(TestAddress.account1)[0].assertionId,
            defaultBond
        );
        _mockOracleResolved(address(mockOracle), oracleRequest, false);

        assertFalse(
            optimisticOracleV3.settleAndGetAssertionResult(
                umaTimeCard.getCheckOutData(TestAddress.account1)[0].assertionId
            )
        );
        assertTrue(
            umaTimeCard.getCheckOutData(TestAddress.account1)[0].isDispute
        );
        assertEq(
            umaTimeCard.getCheckOutData(TestAddress.account1)[0].timestamp,
            0
        );
    }
}
