// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VaultEngine} from "../../src/SCS3/VaultEngine.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract VaultEngineTest is Test {
    VaultEngine public vault;
    SCSEnforcement public enforcement;
    ERC20Mock public asset;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public strategy1 = makeAddr("strategy1");
    address public strategy2 = makeAddr("strategy2");

    uint256 constant INITIAL_DEPOSIT = 1000e18;

    function setUp() public {
        enforcement = new SCSEnforcement();
        asset = new ERC20Mock();
        
        vault = new VaultEngine(
            address(asset),
            address(enforcement),
            "Vault Shares",
            "vSHARE"
        );

        asset.mint(user1, INITIAL_DEPOSIT * 10);
        asset.mint(user2, INITIAL_DEPOSIT * 10);
        asset.mint(strategy1, INITIAL_DEPOSIT);
        asset.mint(strategy2, INITIAL_DEPOSIT);
    }

    function test_VaultCreation() public view {
        assertEq(vault.currentEpoch(), 0);
        assertEq(vault.performanceFeeBps(), 1000);
        assertEq(vault.managementFeeBps(), 200);
        assertTrue(vault.isActive());
    }

    function test_Deposit() public {
        vm.startPrank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        uint256 shares = vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        assertEq(shares, INITIAL_DEPOSIT);
        assertEq(vault.balanceOf(user1), INITIAL_DEPOSIT);
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT);
    }

    function test_Withdraw() public {
        vm.startPrank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        uint256 shares = vault.deposit(INITIAL_DEPOSIT, user1);
        uint256 assets = vault.withdraw(INITIAL_DEPOSIT, user1, user1);
        vm.stopPrank();

        assertEq(assets, shares);
        assertEq(vault.balanceOf(user1), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function test_AddStrategy() public {
        vault.addStrategy(strategy1, 5000); // 50% allocation

        (bool active, uint256 allocation,,) = vault.getStrategyInfo(strategy1);
        assertTrue(active);
        assertEq(allocation, 5000);
    }

    function test_DeployToStrategy() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        vault.addStrategy(strategy1, 5000);
        vault.deployToStrategy(strategy1, INITIAL_DEPOSIT / 2);

        (,, uint256 deployed,) = vault.getStrategyInfo(strategy1);
        assertEq(deployed, INITIAL_DEPOSIT / 2);
        assertEq(vault.totalDeployed(), INITIAL_DEPOSIT / 2);
    }

    function test_RecallFromStrategy() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        vault.addStrategy(strategy1, 5000);
        vault.deployToStrategy(strategy1, INITIAL_DEPOSIT / 2);

        vm.prank(strategy1);
        asset.approve(address(vault), INITIAL_DEPOSIT / 2);
        
        vault.recallFromStrategy(strategy1, INITIAL_DEPOSIT / 2);

        (,, uint256 deployed,) = vault.getStrategyInfo(strategy1);
        assertEq(deployed, 0);
        assertEq(vault.totalDeployed(), 0);
    }

    function test_CalculateNAV() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        assertEq(vault.calculateNAV(), INITIAL_DEPOSIT);

        vault.addStrategy(strategy1, 5000);
        vault.deployToStrategy(strategy1, INITIAL_DEPOSIT / 2);

        assertEq(vault.calculateNAV(), INITIAL_DEPOSIT);
    }

    function test_StartNewEpoch() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        vm.warp(block.timestamp + 7 days);

        vault.startNewEpoch();

        assertEq(vault.currentEpoch(), 1);
    }

    function test_PerformanceFeeCalculation() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        // Simulate profit
        asset.mint(address(vault), 100e18);

        vm.warp(block.timestamp + 7 days);
        vault.startNewEpoch();

        (,, uint256 deposits, uint256 withdrawals, uint256 perfFee) = vault.getEpochData(0);
        
        assertEq(deposits, INITIAL_DEPOSIT);
        assertEq(withdrawals, 0);
        assertEq(perfFee, 10e18); // 10% of 100e18 profit
    }

    function test_RemoveStrategy() public {
        vault.addStrategy(strategy1, 5000);
        vault.removeStrategy(strategy1);

        (bool active,,,) = vault.getStrategyInfo(strategy1);
        assertFalse(active);
    }

    function test_SetPerformanceFee() public {
        vault.setPerformanceFee(1500); // 15%
        assertEq(vault.performanceFeeBps(), 1500);
    }

    function test_PauseUnpause() public {
        vault.pause();
        assertFalse(vault.isActive());

        vault.unpause();
        assertTrue(vault.isActive());
    }

    function test_RevertWhen_UnauthorizedAddStrategy() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.addStrategy(strategy1, 5000);
    }

    function test_RevertWhen_DeployToInactiveStrategy() public {
        vm.prank(user1);
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vm.prank(user1);
        vault.deposit(INITIAL_DEPOSIT, user1);

        vm.expectRevert(VaultEngine.InvalidStrategy.selector);
        vault.deployToStrategy(strategy1, INITIAL_DEPOSIT / 2);
    }

    function test_RevertWhen_EpochNotEnded() public {
        vm.expectRevert(VaultEngine.EpochNotEnded.selector);
        vault.startNewEpoch();
    }

    function testFuzz_DepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1e18, 1000000e18);

        asset.mint(user1, amount);

        vm.startPrank(user1);
        asset.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, user1);
        uint256 assets = vault.withdraw(amount, user1, user1);
        vm.stopPrank();

        assertEq(shares, amount);
        assertEq(assets, amount);
    }
}
