// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ISCS4} from "../../src/interfaces/ISCS4.sol";

contract SCSEnforcementTest is Test {
    SCSEnforcement public enforcement;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        enforcement = new SCSEnforcement();
    }

    function test_ValidateDeployment_Success() public view {
        ISCS4.ValidationResult memory result = enforcement.validateDeployment(1000 ether, 0);
        assertTrue(result.isCompliant);
        assertEq(result.reason, "");
    }

    function test_ValidateDeployment_RejectsGuaranteedReturn() public view {
        ISCS4.ValidationResult memory result = enforcement.validateDeployment(1000 ether, 100 ether);
        assertFalse(result.isCompliant);
        assertEq(result.reason, "Guaranteed returns prohibited (based on AAOIFI standards)");
    }

    function test_ValidateDeployment_RejectsZeroAmount() public view {
        ISCS4.ValidationResult memory result = enforcement.validateDeployment(0, 0);
        assertFalse(result.isCompliant);
        assertEq(result.reason, "Deployment amount must be greater than zero");
    }

    function test_ValidateProfitRatio_Success() public view {
        ISCS4.ValidationResult memory result = enforcement.validateProfitRatio(7000, 3000);
        assertTrue(result.isCompliant);
    }

    function test_ValidateProfitRatio_RejectsInvalidSum() public view {
        ISCS4.ValidationResult memory result = enforcement.validateProfitRatio(6000, 3000);
        assertFalse(result.isCompliant);
        assertEq(result.reason, "Profit shares must sum to 100%");
    }

    function test_ValidateProfitRatio_RejectsZeroShare() public view {
        ISCS4.ValidationResult memory result = enforcement.validateProfitRatio(10000, 0);
        assertFalse(result.isCompliant);
        assertEq(result.reason, "Both parties must receive profit share");
    }

    function test_ValidateLossAllocation_Success() public view {
        // Partner with 30% capital should bear 30% of loss
        uint256 partnerCapital = 300 ether;
        uint256 totalCapital = 1000 ether;
        uint256 totalLoss = 100 ether;
        uint256 partnerLoss = 30 ether;

        ISCS4.ValidationResult memory result =
            enforcement.validateLossAllocation(partnerCapital, totalCapital, partnerLoss, totalLoss);
        assertTrue(result.isCompliant);
    }

    function test_ValidateLossAllocation_RejectsDisproportionate() public view {
        // Partner with 30% capital trying to bear only 20% of loss
        uint256 partnerCapital = 300 ether;
        uint256 totalCapital = 1000 ether;
        uint256 totalLoss = 100 ether;
        uint256 partnerLoss = 20 ether;

        ISCS4.ValidationResult memory result =
            enforcement.validateLossAllocation(partnerCapital, totalCapital, partnerLoss, totalLoss);
        assertFalse(result.isCompliant);
        assertEq(result.reason, "Loss allocation must be proportional to capital (based on AAOIFI Sharia #12)");
    }

    function test_RegisterContract_Success() public {
        address testContract = makeAddr("testContract");
        enforcement.registerContract(testContract, 1);
        assertTrue(enforcement.isCompliantContract(testContract));
        assertEq(enforcement.getContractType(testContract), 1);
    }

    function test_RegisterContract_RevertsIfAlreadyRegistered() public {
        address testContract = makeAddr("testContract");
        enforcement.registerContract(testContract, 1);
        vm.expectRevert(SCSEnforcement.AlreadyRegistered.selector);
        enforcement.registerContract(testContract, 1);
    }

    function test_DeregisterContract_Success() public {
        address testContract = makeAddr("testContract");
        enforcement.registerContract(testContract, 1);
        enforcement.deregisterContract(testContract);
        assertFalse(enforcement.isCompliantContract(testContract));
    }

    function test_RegisterContract_RevertsIfNotOwner() public {
        address testContract = makeAddr("testContract");
        vm.prank(user);
        vm.expectRevert();
        enforcement.registerContract(testContract, 1);
    }

    function testFuzz_ValidateLossAllocation(uint256 partnerCapital, uint256 totalCapital, uint256 totalLoss)
        public
        view
    {
        vm.assume(totalCapital > 0 && totalCapital <= 1e27);
        vm.assume(partnerCapital > 0 && partnerCapital <= totalCapital);
        vm.assume(totalLoss > 0 && totalLoss <= totalCapital);

        uint256 expectedLoss = (partnerCapital * totalLoss) / totalCapital;

        ISCS4.ValidationResult memory result =
            enforcement.validateLossAllocation(partnerCapital, totalCapital, expectedLoss, totalLoss);
        assertTrue(result.isCompliant);
    }
}
