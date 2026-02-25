// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ShariaBoard} from "../../src/SCS5/ShariaBoard.sol";
import {ShariaGovernance} from "../../src/SCS5/ShariaGovernance.sol";
import {ISCS5} from "../../src/interfaces/ISCS5.sol";

contract SCS5Test is Test {
    ShariaBoard public board;
    ShariaGovernance public governance;

    address public owner = address(this);
    address public member1 = makeAddr("member1");
    address public member2 = makeAddr("member2");
    address public member3 = makeAddr("member3");
    address public nonMember = makeAddr("nonMember");

    function setUp() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;

        board = new ShariaBoard(members, 2); // 2 of 3 required
        governance = new ShariaGovernance(address(board));
    }

    function test_BoardCreation() public view {
        assertEq(board.memberCount(), 3);
        assertEq(board.requiredApprovals(), 2);
        assertTrue(board.isSSBMember(member1));
        assertTrue(board.isSSBMember(member2));
        assertTrue(board.isSSBMember(member3));
    }

    function test_SubmitProposal() public {
        vm.prank(member1);
        bytes32 proposalId = board.submitProposal(
            "Test Proposal",
            address(governance),
            "",
            ShariaBoard.ProposalType.INVESTMENT
        );

        (string memory desc,, uint256 approvals, bool executed,) = board.getProposal(proposalId);
        assertEq(desc, "Test Proposal");
        assertEq(approvals, 0);
        assertFalse(executed);
    }

    function test_ApproveProposal() public {
        vm.prank(member1);
        bytes32 proposalId = board.submitProposal(
            "Test Proposal",
            address(governance),
            "",
            ShariaBoard.ProposalType.INVESTMENT
        );

        vm.prank(member1);
        board.approveProposal(proposalId);

        (,, uint256 approvals,,) = board.getProposal(proposalId);
        assertEq(approvals, 1);
    }

    function test_ExecuteProposal() public {
        // Transfer ownership to board so it can execute
        governance.transferOwnership(address(board));

        vm.prank(member1);
        bytes32 proposalId = board.submitProposal(
            "Test Proposal",
            address(governance),
            abi.encodeWithSignature("setMaxDebtRatio(uint256)", 4000),
            ShariaBoard.ProposalType.PARAMETER_CHANGE
        );

        vm.prank(member1);
        board.approveProposal(proposalId);

        vm.prank(member2);
        board.approveProposal(proposalId);

        assertTrue(board.isProposalApproved(proposalId));

        vm.prank(member1);
        bool success = board.executeProposal(proposalId);

        assertTrue(success);
        (,,, bool executed,) = board.getProposal(proposalId);
        assertTrue(executed);
        assertEq(governance.maxDebtRatio(), 4000);
    }

    function test_AddMember() public {
        address newMember = makeAddr("newMember");
        board.addMember(newMember);

        assertTrue(board.isSSBMember(newMember));
        assertEq(board.memberCount(), 4);
    }

    function test_RemoveMember() public {
        board.removeMember(member3);

        assertFalse(board.isSSBMember(member3));
        assertEq(board.memberCount(), 2);
    }

    function test_ProhibitAsset() public {
        address asset = makeAddr("asset");
        governance.prohibitAsset(asset);

        assertTrue(governance.prohibitedAssets(asset));
    }

    function test_ScreenAsset() public {
        address asset = makeAddr("asset");
        governance.screenAsset(asset, true, "Compliant");

        (bool screened, bool compliant,, string memory reason) = governance.getAssetScreening(asset);
        assertTrue(screened);
        assertTrue(compliant);
        assertEq(reason, "Compliant");
    }

    function test_ValidateAsset() public {
        address asset = makeAddr("asset");
        governance.screenAsset(asset, true, "Compliant");

        assertTrue(governance.validateAsset(asset));
    }

    function test_ValidateFinancialRatios() public {
        assertTrue(governance.validateFinancialRatios(1000e18, 300e18, 200e18));
    }

    function test_SetMaxDebtRatio() public {
        governance.setMaxDebtRatio(4000);
        assertEq(governance.maxDebtRatio(), 4000);
    }

    function test_RevertWhen_NonMemberSubmitsProposal() public {
        vm.prank(nonMember);
        vm.expectRevert(ShariaBoard.NotSSBMember.selector);
        board.submitProposal("Test", address(0), "", ShariaBoard.ProposalType.INVESTMENT);
    }

    function test_RevertWhen_ExecuteWithoutApprovals() public {
        vm.prank(member1);
        bytes32 proposalId = board.submitProposal(
            "Test",
            address(governance),
            "",
            ShariaBoard.ProposalType.INVESTMENT
        );

        vm.prank(member1);
        vm.expectRevert(ShariaBoard.ProposalNotApproved.selector);
        board.executeProposal(proposalId);
    }

    function test_RevertWhen_ProhibitedAsset() public {
        address asset = makeAddr("asset");
        governance.prohibitAsset(asset);

        vm.expectRevert(ShariaGovernance.AssetIsProhibited.selector);
        governance.validateAsset(asset);
    }

    function test_RevertWhen_AssetNotScreened() public {
        address asset = makeAddr("asset");

        vm.expectRevert(ShariaGovernance.AssetNotScreened.selector);
        governance.validateAsset(asset);
    }

    function test_RevertWhen_DebtRatioExceeded() public {
        vm.expectRevert(ShariaGovernance.RatioExceeded.selector);
        governance.validateFinancialRatios(1000e18, 400e18, 200e18); // 40% debt
    }

    function testFuzz_FinancialRatios(uint256 assets, uint256 debt, uint256 interest) public {
        assets = bound(assets, 1e18, 1000000e18);
        debt = bound(debt, 0, (assets * 3300) / 10000);
        interest = bound(interest, 0, (assets * 3000) / 10000);

        assertTrue(governance.validateFinancialRatios(assets, debt, interest));
    }
}
