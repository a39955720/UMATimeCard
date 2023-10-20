// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import {CommonOptimisticOracleV3Test} from "@protocol/packages/core/test/foundry/optimistic-oracle-v3/CommonOptimisticOracleV3Test.sol";
import {TestAddress} from "@protocol/packages/core/test/foundry/fixtures/common/TestAddress.sol";
import {UMATimeCard} from "../src/UMATimeCard.sol";
import {UMATimeCardEntrance} from "../src/UMATimeCardEntrance.sol";
import {LZEndpointMock} from "@LayerZero/contracts/lzApp/mocks/LZEndpointMock.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract UMATimeCardTest is CommonOptimisticOracleV3Test {
    UMATimeCard umaTimeCard;
    UMATimeCardEntrance umaTimeCardEntrance;
    LZEndpointMock lZEndpointMock;
    address owner = 0x6Ec373C59C1f68B2C984640e63cb38f2E2d34f8C;
    uint256 fee = 0.5 ether;
    string url = "https://github.com/a39955720/UMATimeCard";

    function setUp() public {
        vm.deal(TestAddress.account1, 10 ether);
        _commonSetup();
        lZEndpointMock = new LZEndpointMock(123);
        vm.startPrank(owner);
        umaTimeCard = new UMATimeCard(
            address(defaultCurrency),
            address(optimisticOracleV3),
            address(lZEndpointMock)
        );
        umaTimeCardEntrance = new UMATimeCardEntrance(
            123,
            address(lZEndpointMock)
        );
        vm.stopPrank();

        lZEndpointMock.setDestLzEndpoint(
            address(umaTimeCard),
            address(lZEndpointMock)
        );
        lZEndpointMock.setDestLzEndpoint(
            address(umaTimeCardEntrance),
            address(lZEndpointMock)
        );

        vm.startPrank(owner);
        umaTimeCard.setTrustedRemoteAddress(
            123,
            abi.encodePacked(address(umaTimeCardEntrance))
        );
        umaTimeCardEntrance.setTrustedRemoteAddress(
            123,
            abi.encodePacked(address(umaTimeCard))
        );
        vm.stopPrank();

        vm.startPrank(address(umaTimeCard));
        defaultCurrency.allocateTo(
            address(address(umaTimeCard)),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency)) * 5
        );
        defaultCurrency.approve(
            address(umaTimeCard),
            optimisticOracleV3.getMinimumBond(address(defaultCurrency)) * 5
        );
        vm.stopPrank();
    }

    function testCrossChainOperation() public {
        uint256 blocktimestamp = block.timestamp;
        vm.prank(TestAddress.account1);
        umaTimeCardEntrance.send{value: fee}(0, url);

        assertFalse(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].isDispute
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            blocktimestamp
        );

        timer.setCurrentTime(timer.getCurrentTime() + 120);

        vm.prank(TestAddress.account1);
        umaTimeCardEntrance.send{value: fee}(1, url);

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
    }

    function testRevert() public {
        vm.startPrank(address(umaTimeCard));
        bytes memory customError = abi.encodeWithSignature(
            "UMATimeCard__YouShouldCheckInFirst()"
        );
        vm.expectRevert(customError);
        umaTimeCard.checkOut(block.timestamp, TestAddress.account1, url);

        umaTimeCard.checkIn(block.timestamp, TestAddress.account1, url);

        customError = abi.encodeWithSignature(
            "UMATimeCard__YouShouldCheckOutFirst()"
        );
        vm.expectRevert(customError);
        umaTimeCard.checkIn(block.timestamp, TestAddress.account1, url);
        timer.setCurrentTime(timer.getCurrentTime() + 120);
        vm.stopPrank();

        customError = abi.encodeWithSignature(
            "UMATimeCard__YouCantCallThisFunction()"
        );
        vm.expectRevert(customError);
        umaTimeCard.checkOut(block.timestamp, TestAddress.account1, url);

        vm.prank(address(umaTimeCard));
        umaTimeCard.checkOut(block.timestamp, TestAddress.account1, url);
        timer.setCurrentTime(timer.getCurrentTime() + 120);

        vm.expectRevert(customError);
        umaTimeCard.checkIn(block.timestamp, TestAddress.account1, url);
    }

    function test_CheckInOutNoDispute() public {
        vm.startPrank(address(umaTimeCard));

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1, url);

        assertFalse(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].isDispute
        );
        assertEq(
            umaTimeCard.getCheckInData(TestAddress.account1)[0].timestamp,
            blocktimestamp
        );

        timer.setCurrentTime(timer.getCurrentTime() + 120);
        vm.warp(timer.getCurrentTime());
        console.log(block.timestamp);

        umaTimeCard.checkOut(block.timestamp, TestAddress.account1, url);

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
        assertEq(
            umaTimeCard.getCheckOutData(TestAddress.account1)[0].timestamp,
            blocktimestamp + 120
        );
        vm.stopPrank();
    }

    function test_CheckInOrOutWithWrongDispute() public {
        vm.startPrank(address(umaTimeCard));

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1, url);
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
        vm.startPrank(address(umaTimeCard));

        uint256 blocktimestamp = block.timestamp;
        umaTimeCard.checkIn(blocktimestamp, TestAddress.account1, url);
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

        vm.startPrank(address(umaTimeCard));

        blocktimestamp = block.timestamp;
        umaTimeCard.checkOut(blocktimestamp, TestAddress.account1, url);
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
