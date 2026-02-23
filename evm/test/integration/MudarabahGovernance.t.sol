// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MudarabahPool} from "../../src/SCS1/MudarabahPool.sol";
import {MudarabahFactory} from "../../src/SCS1/MudarabahFactory.sol";
import {ShariaBoard} from "../../src/SCS5/ShariaBoard.sol";
import {AAOIFIGovernance} from "../../src/SCS5/AAOIFIGovernance.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/// @title Integration Test: Mudarabah + Governance
/// @notice Tests SCS-1 Mudarabah with SCS-5 Governance oversight
contract MudarabahGovernanceIntegrationTest is Test {
    MudarabahPool public pool;
    MudarabahFactory public factory;
    ShariaBoard public board;
    AAOIFIGovernance public governance;
    SCSEnforcement public enforcement;
    ERC20Mock public asset;

    address public manager = makeAddr("manager");
    address public provider = makeAddr("provider");
    address public strategy = makeAddr("strategy");
    address public scholar1 = makeAddr("scholar1");
    address public scholar2 = makeAddr("scholar2");
    address public scholar3 = makeAddr("scholar3");

    uint256 constant INITIAL_CAPITAL = 1000e18;

    function setUp() public {
        // Deploy core infrastructure
        enforcement = new SCSEnforcement();
        asset = new ERC20Mock();

        // Deploy Sharia Board
        address[] memory members = new address[](3);
        members[0] = scholar1;
        members[1] = scholar2;
        members[2] = scholar3;
        board = new ShariaBoard(members, 2);

        // Deploy governance
        governance = new AAOIFIGovernance(address(board));
        
        // Screen asset as compliant (before transferring ownership)
        governance.screenAsset(address(asset), true, "Stablecoin - Compliant");
        
        // Transfer ownership to board
        governance.transferOwnership(address(board));

        // Deploy Mudarabah factory
        factory = new MudarabahFactory(address(enforcement));

        // Mint tokens
        asset.mint(provider, INITIAL_CAPITAL * 10);
        asset.mint(strategy, INITIAL_CAPITAL);
    }

    function test_GovernedMudarabahPoolCreation() public {
        // Create pool through factory
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000, // 20% manager
            8000, // 80% provider
            "Governed Mudarabah",
            "GMD"
        );

        pool = MudarabahPool(poolAddr);

        // Verify pool created
        assertEq(pool.manager(), manager);
        assertEq(pool.capitalProvider(), provider);
        assertTrue(pool.isActive());
    }

    function test_SSBApprovedStrategyDeployment() public {
        // Create pool
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Governed Mudarabah",
            "GMD"
        );
        pool = MudarabahPool(poolAddr);

        // Provider deposits
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        pool.deposit(INITIAL_CAPITAL);
        vm.stopPrank();

        // SSB approves strategy
        bytes32 strategyHash = keccak256(abi.encodePacked(strategy));
        
        vm.prank(scholar1);
        board.approveStrategy(strategyHash);
        
        vm.prank(scholar2);
        board.approveStrategy(strategyHash);

        assertTrue(board.isStrategyApproved(strategyHash));

        // Manager deploys to approved strategy
        vm.prank(manager);
        pool.deployCapital(strategy, INITIAL_CAPITAL / 2);

        assertEq(pool.deployedCapital(), INITIAL_CAPITAL / 2);
    }

    function test_AssetScreeningBeforeDeployment() public {
        // Create pool
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Governed Mudarabah",
            "GMD"
        );
        pool = MudarabahPool(poolAddr);

        // Verify asset is screened and compliant
        assertTrue(governance.validateAsset(address(asset)));

        // Provider can deposit compliant asset
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        pool.deposit(INITIAL_CAPITAL);
        vm.stopPrank();

        assertEq(pool.totalCapital(), INITIAL_CAPITAL);
    }

    function test_FinancialRatioValidation() public {
        // Create pool
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Governed Mudarabah",
            "GMD"
        );
        pool = MudarabahPool(poolAddr);

        // Deposit capital
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        pool.deposit(INITIAL_CAPITAL);
        vm.stopPrank();

        // Validate financial ratios
        bool compliant = governance.validateFinancialRatios(
            INITIAL_CAPITAL, // total assets
            300e18,          // debt (30%)
            200e18           // interest income (20%)
        );

        assertTrue(compliant);
    }

    function test_ProhibitedAssetPreventsDeployment() public {
        // Create pool
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Governed Mudarabah",
            "GMD"
        );
        pool = MudarabahPool(poolAddr);

        // Prohibit the asset
        vm.prank(scholar1);
        bytes32 proposalId = board.submitProposal(
            "Prohibit asset",
            address(governance),
            abi.encodeWithSignature("prohibitAsset(address)", address(asset)),
            ShariaBoard.ProposalType.ASSET_SCREENING
        );

        vm.prank(scholar1);
        board.approveProposal(proposalId);
        vm.prank(scholar2);
        board.approveProposal(proposalId);
        vm.prank(scholar1);
        board.executeProposal(proposalId);

        // Asset should now be prohibited
        vm.expectRevert(AAOIFIGovernance.AssetIsProhibited.selector);
        governance.validateAsset(address(asset));
    }

    function test_EndToEndGovernedMudarabah() public {
        // 1. Create pool
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Governed Mudarabah",
            "GMD"
        );
        pool = MudarabahPool(poolAddr);

        // 2. Validate asset compliance
        assertTrue(governance.validateAsset(address(asset)));

        // 3. Provider deposits
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        pool.deposit(INITIAL_CAPITAL);
        vm.stopPrank();

        // 4. SSB approves strategy
        bytes32 strategyHash = keccak256(abi.encodePacked(strategy));
        vm.prank(scholar1);
        board.approveStrategy(strategyHash);
        vm.prank(scholar2);
        board.approveStrategy(strategyHash);

        // 5. Manager deploys capital
        vm.prank(manager);
        pool.deployCapital(strategy, 500e18);

        // 6. Strategy returns with profit
        asset.mint(strategy, 100e18);
        vm.startPrank(strategy);
        asset.approve(address(pool), 600e18);
        pool.returnCapital(0, 600e18);
        vm.stopPrank();

        // 7. Distribute profits
        vm.prank(manager);
        pool.distributeProfits();

        // 8. Validate financial ratios
        assertTrue(governance.validateFinancialRatios(
            pool.totalCapital(),
            0,
            0
        ));

        // Verify final state
        assertGt(pool.totalCapital(), INITIAL_CAPITAL);
    }
}
