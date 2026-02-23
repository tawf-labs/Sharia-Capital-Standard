// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MusharakahPool} from "../../src/SCS2/MusharakahPool.sol";
import {MusharakahFactory} from "../../src/SCS2/MusharakahFactory.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MusharakahPoolTest is Test {
    MusharakahPool public pool;
    MusharakahFactory public factory;
    SCSEnforcement public enforcement;
    ERC20Mock public asset;

    address public partner1 = makeAddr("partner1");
    address public partner2 = makeAddr("partner2");
    address public partner3 = makeAddr("partner3");
    address public strategy = makeAddr("strategy");

    uint256 constant INITIAL_CAPITAL = 1000e18;

    function setUp() public {
        enforcement = new SCSEnforcement();
        asset = new ERC20Mock();
        factory = new MusharakahFactory(address(enforcement));

        address[] memory partners = new address[](3);
        partners[0] = partner1;
        partners[1] = partner2;
        partners[2] = partner3;

        uint256[] memory profitShares = new uint256[](3);
        profitShares[0] = 5000; // 50%
        profitShares[1] = 3000; // 30%
        profitShares[2] = 2000; // 20%

        address poolAddr = factory.createPool(
            address(asset),
            partners,
            profitShares,
            "Musharakah Pool",
            "MSP"
        );

        pool = MusharakahPool(poolAddr);

        asset.mint(partner1, INITIAL_CAPITAL * 10);
        asset.mint(partner2, INITIAL_CAPITAL * 10);
        asset.mint(partner3, INITIAL_CAPITAL * 10);
        asset.mint(strategy, INITIAL_CAPITAL);
    }

    function test_PoolCreation() public view {
        address[] memory partners = pool.getPartners();
        assertEq(partners.length, 3);
        assertEq(partners[0], partner1);
        assertEq(partners[1], partner2);
        assertEq(partners[2], partner3);
    }

    function test_ContributeCapital() public {
        vm.startPrank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        uint256 shares = pool.contributeCapital(INITIAL_CAPITAL);
        vm.stopPrank();

        assertEq(shares, INITIAL_CAPITAL);
        assertEq(pool.balanceOf(partner1), INITIAL_CAPITAL);
        assertEq(pool.totalCapital(), INITIAL_CAPITAL);
    }

    function test_MultiplePartnerContributions() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        vm.prank(partner2);
        asset.approve(address(pool), INITIAL_CAPITAL / 2);
        vm.prank(partner2);
        pool.contributeCapital(INITIAL_CAPITAL / 2);

        assertEq(pool.totalCapital(), INITIAL_CAPITAL + INITIAL_CAPITAL / 2);
    }

    function test_WithdrawCapital() public {
        vm.startPrank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        uint256 shares = pool.contributeCapital(INITIAL_CAPITAL);
        uint256 amount = pool.withdrawCapital(shares);
        vm.stopPrank();

        assertEq(amount, INITIAL_CAPITAL);
        assertEq(pool.balanceOf(partner1), 0);
        assertEq(pool.totalCapital(), 0);
    }

    function test_DeployCapital() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        vm.prank(partner1);
        pool.deployCapital(strategy, INITIAL_CAPITAL / 2);

        assertEq(pool.deployedCapital(), INITIAL_CAPITAL / 2);
        assertEq(pool.availableCapital(), INITIAL_CAPITAL / 2);
    }

    function test_ReturnCapital() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        vm.prank(partner1);
        pool.deployCapital(strategy, INITIAL_CAPITAL / 2);

        vm.startPrank(strategy);
        asset.approve(address(pool), INITIAL_CAPITAL / 2);
        pool.returnCapital(INITIAL_CAPITAL / 2);
        vm.stopPrank();

        assertEq(pool.deployedCapital(), 0);
        assertEq(pool.availableCapital(), INITIAL_CAPITAL);
    }

    function test_DistributeProfits() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        uint256 profit = 100e18;
        asset.mint(address(pool), profit);

        vm.prank(partner1);
        pool.distributeProfits();

        assertEq(pool.totalCapital(), INITIAL_CAPITAL + profit);
    }

    function test_AllocateLoss() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        vm.prank(partner2);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner2);
        pool.contributeCapital(INITIAL_CAPITAL);

        uint256 loss = 200e18;

        vm.prank(partner1);
        pool.allocateLoss(loss);

        assertEq(pool.totalCapital(), 2 * INITIAL_CAPITAL - loss);
    }

    function test_ProportionalLossAllocation() public {
        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        vm.prank(partner2);
        asset.approve(address(pool), INITIAL_CAPITAL / 2);
        vm.prank(partner2);
        pool.contributeCapital(INITIAL_CAPITAL / 2);

        uint256 loss = 150e18;

        vm.prank(partner1);
        pool.allocateLoss(loss);

        (uint256 p1Capital,,) = pool.getPartnerInfo(partner1);
        (uint256 p2Capital,,) = pool.getPartnerInfo(partner2);

        assertEq(p1Capital, INITIAL_CAPITAL - 100e18);
        assertEq(p2Capital, INITIAL_CAPITAL / 2 - 50e18);
    }

    function test_Terminate() public {
        vm.prank(partner1);
        pool.terminate();

        assertFalse(pool.isActive());
    }

    function test_RevertWhen_UnauthorizedContribution() public {
        address nonPartner = makeAddr("nonPartner");
        vm.prank(nonPartner);
        vm.expectRevert(MusharakahPool.Unauthorized.selector);
        pool.contributeCapital(INITIAL_CAPITAL);
    }

    function test_RevertWhen_InvalidProfitShares() public {
        address[] memory partners = new address[](2);
        partners[0] = partner1;
        partners[1] = partner2;

        uint256[] memory profitShares = new uint256[](2);
        profitShares[0] = 6000;
        profitShares[1] = 3000; // Total = 9000, not 10000

        vm.expectRevert(MusharakahFactory.InvalidProfitShares.selector);
        factory.createPool(
            address(asset),
            partners,
            profitShares,
            "Invalid Pool",
            "INV"
        );
    }

    function testFuzz_ProfitDistribution(uint256 profit) public {
        profit = bound(profit, 1e18, 1000000e18);

        vm.prank(partner1);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(partner1);
        pool.contributeCapital(INITIAL_CAPITAL);

        asset.mint(address(pool), profit);

        vm.prank(partner1);
        pool.distributeProfits();

        assertGe(pool.totalCapital(), INITIAL_CAPITAL + profit - 2);
        assertLe(pool.totalCapital(), INITIAL_CAPITAL + profit + 2);
    }
}
