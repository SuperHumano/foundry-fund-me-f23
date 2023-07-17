// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");

    uint256 constant VALUE_TEST = 1e16;
    uint256 constant STARTING_BALANCE = 1e18;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testMinimumDolIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testPriceFeedVersionAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier toFund() {
        vm.prank(USER);
        fundMe.fund{value: VALUE_TEST}();
        _;
    }

    function testFundUpdatesDataStructure() public toFund {
        uint256 amountFunded = fundMe.getAddressToAmountFounded(USER);
        assertEq(amountFunded, VALUE_TEST);
    }

    function testAddFunderToArrOfFunders() public toFund {
        assertEq(fundMe.getFunder(0), USER);
    }

    function testOnlyOwnerCanWithdraw() public toFund {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.cheaperWithdraw();
    }

    function testCheaperWithdrawWithSingleFunder() public toFund {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testCheaperWithdrawWithMultipleFunders() public toFund {
        uint160 peopleQuantity = 10;
        uint160 funderIdx = 1;
        for (uint160 i = funderIdx; i < peopleQuantity; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: STARTING_BALANCE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }
}
