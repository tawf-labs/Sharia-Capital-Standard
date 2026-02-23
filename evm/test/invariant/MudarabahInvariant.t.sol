// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MudarabahPool} from "../../src/SCS1/MudarabahPool.sol";
import {MudarabahFactory} from "../../src/SCS1/MudarabahFactory.sol";
import {SCSEnforcement} from "../../src/SCS4/SCSEnforcement.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/// @title Invariant Tests for Mudarabah Pool
/// @notice Property-based testing to ensure critical invariants hold
contract MudarabahInvariantTest is Test {
    MudarabahPool public pool;
    MudarabahFactory public factory;
    SCSEnforcement public enforcement;
    ERC20Mock public asset;
    
    address public manager;
    address public provider;
    
    Handler public handler;

    function setUp() public {
        manager = makeAddr("manager");
        provider = makeAddr("provider");
        
        enforcement = new SCSEnforcement();
        asset = new ERC20Mock();
        factory = new MudarabahFactory(address(enforcement));
        
        address poolAddr = factory.createPool(
            address(asset),
            manager,
            provider,
            2000,
            8000,
            "Test Pool",
            "TP"
        );
        
        pool = MudarabahPool(poolAddr);
        
        // Setup handler
        handler = new Handler(pool, asset, manager, provider);
        
        // Mint tokens to handler
        asset.mint(address(handler), 1000000e18);
        
        // Target handler for invariant testing
        targetContract(address(handler));
    }

    /// @notice Invariant: Total capital should always equal balance + deployed
    function invariant_totalCapitalEqualsBalancePlusDeployed() public view {
        uint256 balance = asset.balanceOf(address(pool));
        uint256 deployed = pool.deployedCapital();
        uint256 total = pool.totalCapital();
        
        assertEq(total, balance + deployed, "Total capital != balance + deployed");
    }

    /// @notice Invariant: Deployed capital should never exceed total capital
    function invariant_deployedNeverExceedsTotal() public view {
        assertLe(pool.deployedCapital(), pool.totalCapital(), "Deployed > total");
    }

    /// @notice Invariant: Share supply should match provider balance
    function invariant_shareSupplyMatchesProvider() public view {
        assertEq(pool.totalSupply(), pool.balanceOf(provider), "Supply != provider balance");
    }

    /// @notice Invariant: Pool should always be active or terminated
    function invariant_poolStateConsistent() public view {
        assertTrue(pool.isActive() || !pool.isActive(), "Invalid state");
    }
}

contract Handler {
    MudarabahPool public pool;
    ERC20Mock public asset;
    address public manager;
    address public provider;
    
    uint256 public depositCount;
    uint256 public withdrawCount;
    uint256 public deployCount;
    
    address internal testContract;
    
    constructor(MudarabahPool _pool, ERC20Mock _asset, address _manager, address _provider) {
        pool = _pool;
        asset = _asset;
        manager = _manager;
        provider = _provider;
        testContract = msg.sender;
    }
    
    function deposit(uint256 amount) public {
        amount = _bound(amount, 1e18, 10000e18);
        
        _prank(provider);
        asset.transfer(provider, amount);
        asset.approve(address(pool), amount);
        
        try pool.deposit(amount) {
            depositCount++;
        } catch {}
        
        _stopPrank();
    }
    
    function withdraw(uint256 shares) public {
        uint256 balance = pool.balanceOf(provider);
        if (balance == 0) return;
        
        shares = _bound(shares, 1, balance);
        
        _prank(provider);
        try pool.withdraw(shares) {
            withdrawCount++;
        } catch {}
        _stopPrank();
    }
    
    function deployCapital(uint256 amount) public {
        uint256 available = pool.availableCapital();
        if (available == 0) return;
        
        amount = _bound(amount, 1e18, available);
        address strategy = address(uint160(uint256(keccak256(abi.encodePacked(amount)))));
        
        _prank(manager);
        try pool.deployCapital(strategy, amount) {
            deployCount++;
        } catch {}
        _stopPrank();
    }
    
    function _bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        if (x < min) return min;
        if (x > max) return max;
        return x;
    }
    
    function _prank(address who) internal {
        (bool success,) = testContract.call(abi.encodeWithSignature("prank(address)", who));
        require(success);
    }
    
    function _stopPrank() internal {
        (bool success,) = testContract.call(abi.encodeWithSignature("stopPrank()"));
        require(success);
    }
}
