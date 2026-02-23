// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MudarabahPool} from "../../src/SCS1/MudarabahPool.sol";
import {MudarabahFactory} from "../../src/SCS1/MudarabahFactory.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MudarabahPoolTest is Test {
    MudarabahPool public pool;
    MudarabahFactory public factory;
    SCSEnforcement public enforcement;
    ERC20Mock public asset;

    address public manager = makeAddr("manager");
    address public provider = makeAddr("provider");
    address public strategy = makeAddr("strategy");

    uint256 constant MANAGER_SHARE_BPS = 2000; // 20%
    uint256 constant PROVIDER_SHARE_BPS = 8000; // 80%
    uint256 constant INITIAL_CAPITAL = 1000e18;

    function setUp() public {
        enforcement = new SCSEnforcement();
        asset = new ERC20Mock();
        
        factory = new MudarabahFactory(address(enforcement));
        
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            MANAGER_SHARE_BPS,
            PROVIDER_SHARE_BPS,
            "Mudarabah Pool",
            "MDP"
        );
        
        pool = MudarabahPool(poolAddr);
        
        asset.mint(provider, INITIAL_CAPITAL * 10);
        asset.mint(strategy, INITIAL_CAPITAL);
    }

    function test_PoolCreation() public view {
        assertEq(pool.manager(), manager);
        assertEq(pool.capitalProvider(), provider);
        assertEq(pool.mudaribShareBps(), MANAGER_SHARE_BPS);
        assertEq(pool.capitalProviderShareBps(), PROVIDER_SHARE_BPS);
        assertEq(pool.totalCapital(), 0);
        assertEq(pool.deployedCapital(), 0);
        assertTrue(pool.isActive());
    }

    function test_Deposit() public {
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        uint256 shares = pool.deposit(INITIAL_CAPITAL);
        vm.stopPrank();

        assertEq(shares, INITIAL_CAPITAL);
        assertEq(pool.balanceOf(provider), INITIAL_CAPITAL);
        assertEq(pool.totalCapital(), INITIAL_CAPITAL);
    }

    function test_Withdraw() public {
        vm.startPrank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        uint256 shares = pool.deposit(INITIAL_CAPITAL);
        uint256 amount = pool.withdraw(shares);
        vm.stopPrank();

        assertEq(amount, INITIAL_CAPITAL);
        assertEq(pool.balanceOf(provider), 0);
        assertEq(pool.totalCapital(), 0);
    }

    function test_DeployCapital() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        vm.prank(manager);
        uint256 deploymentId = pool.deployCapital(strategy, INITIAL_CAPITAL / 2);

        assertEq(deploymentId, 0);
        assertEq(pool.deployedCapital(), INITIAL_CAPITAL / 2);
        assertEq(pool.availableCapital(), INITIAL_CAPITAL / 2);
    }

    function test_RecallCapital() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        vm.prank(manager);
        uint256 deploymentId = pool.deployCapital(strategy, INITIAL_CAPITAL / 2);

        vm.startPrank(strategy);
        asset.approve(address(pool), INITIAL_CAPITAL / 2);
        pool.returnCapital(deploymentId, INITIAL_CAPITAL / 2);
        vm.stopPrank();

        assertEq(pool.deployedCapital(), 0);
        assertEq(pool.availableCapital(), INITIAL_CAPITAL);
    }

    function test_DistributeProfits() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        uint256 profit = 100e18;
        asset.mint(address(pool), profit);

        uint256 managerBalanceBefore = asset.balanceOf(manager);

        vm.prank(manager);
        pool.distributeProfits();

        uint256 expectedManagerAmount = (profit * MANAGER_SHARE_BPS) / 10000;
        uint256 expectedProviderAmount = profit - expectedManagerAmount;

        assertEq(asset.balanceOf(manager) - managerBalanceBefore, expectedManagerAmount);
        assertEq(pool.totalCapital(), INITIAL_CAPITAL + expectedProviderAmount);
    }

    function test_ClaimProfit() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        uint256 profit = 100e18;
        asset.mint(address(pool), profit);

        vm.prank(manager);
        uint256 claimed = pool.claimProfit();

        uint256 expectedManagerAmount = (profit * MANAGER_SHARE_BPS) / 10000;
        assertEq(claimed, expectedManagerAmount);
    }

    function test_RecordLoss() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        uint256 loss = 100e18;

        vm.prank(manager);
        pool.recordLoss(loss);

        assertEq(pool.totalCapital(), INITIAL_CAPITAL - loss);
    }

    function test_Terminate() public {
        vm.prank(provider);
        pool.terminate();

        assertFalse(pool.isActive());
    }

    function test_RevertWhen_UnauthorizedDeposit() public {
        vm.prank(manager);
        vm.expectRevert(MudarabahPool.Unauthorized.selector);
        pool.deposit(INITIAL_CAPITAL);
    }

    function test_RevertWhen_UnauthorizedDeploy() public {
        vm.prank(provider);
        vm.expectRevert(MudarabahPool.Unauthorized.selector);
        pool.deployCapital(strategy, INITIAL_CAPITAL);
    }

    function test_RevertWhen_InsufficientCapital() public {
        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        uint256 shares = pool.deposit(INITIAL_CAPITAL);

        vm.prank(manager);
        pool.deployCapital(strategy, INITIAL_CAPITAL);

        vm.prank(provider);
        vm.expectRevert(MudarabahPool.InsufficientCapital.selector);
        pool.withdraw(shares);
    }

    function testFuzz_ProfitDistribution(uint256 profit) public {
        profit = bound(profit, 1e18, 1000000e18);

        vm.prank(provider);
        asset.approve(address(pool), INITIAL_CAPITAL);
        vm.prank(provider);
        pool.deposit(INITIAL_CAPITAL);

        asset.mint(address(pool), profit);

        vm.prank(manager);
        pool.distributeProfits();

        uint256 expectedManagerAmount = (profit * MANAGER_SHARE_BPS) / 10000;
        uint256 expectedProviderAmount = profit - expectedManagerAmount;

        assertEq(pool.totalCapital(), INITIAL_CAPITAL + expectedProviderAmount);
    }
}
