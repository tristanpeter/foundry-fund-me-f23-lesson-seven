// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMeInstance;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMeInstance = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarAmountIsFive() public {
        assertEq(fundMeInstance.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        console.log(fundMeInstance.getOwner());
        console.log(msg.sender);
        assertEq(fundMeInstance.getOwner(), msg.sender);
    }

    function testGetVersionWorks() public {
        uint256 version = fundMeInstance.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    // we want this to fail so we use a cheat code called expectRevert()
    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMeInstance.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMeInstance.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // 1) Test mapping maps the value sent by sender to addressToAmountFunded mapping
        // 2) Test funders array is updated with the msg.sender address

        uint256 amountFunded = fundMeInstance.getAddressToAmountFunded(address(USER));
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMeInstance.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMeInstance.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMeInstance).balance;

        // Act

        vm.prank(fundMeInstance.getOwner());
        fundMeInstance.withdraw();

        // Assert
        uint256 closingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 closingFundMeBalance = address(fundMeInstance).balance;
        assertEq(closingOwnerBalance, (startingOwnerBalance + startingFundMeBalance));
        assertEq(closingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // starting at 1, not 0, because address(0) sometimes reverts.
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new addresses
            // vm.deal new addresses some money
            // fund me the fundMeInstance
            hoax(address(i), SEND_VALUE);
            fundMeInstance.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 startingFundMeInstanceBalance = address(fundMeInstance).balance;

        // Act

        vm.startPrank(fundMeInstance.getOwner()); // Pretend to be this address, and run code in between startPrank and stopPrank as this owner
        fundMeInstance.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMeInstance).balance == 0);
        assert(startingFundMeInstanceBalance + startingOwnerBalance == fundMeInstance.getOwner().balance);
    }

    function testWithdrawWithASingleFunderCheaper() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMeInstance).balance;

        // Act
        vm.prank(fundMeInstance.getOwner());
        fundMeInstance.cheaperWithdraw();

        // Assert
        uint256 closingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 closingFundMeBalance = address(fundMeInstance).balance;
        assertEq(closingOwnerBalance, (startingOwnerBalance + startingFundMeBalance));
        assertEq(closingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // starting at 1, not 0, because address(0) sometimes reverts.
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new addresses
            // vm.deal new addresses some money
            // fund me the fundMeInstance
            hoax(address(i), SEND_VALUE);
            fundMeInstance.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMeInstance.getOwner().balance;
        uint256 startingFundMeInstanceBalance = address(fundMeInstance).balance;

        // Act
        vm.startPrank(fundMeInstance.getOwner()); // Pretend to be this address, and run code in between startPrank and stopPrank as this owner
        fundMeInstance.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMeInstance).balance == 0);
        assert(startingFundMeInstanceBalance + startingOwnerBalance == fundMeInstance.getOwner().balance);
    }
}
