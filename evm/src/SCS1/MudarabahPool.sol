// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISCS1} from "../interfaces/ISCS1.sol";
import {ISCS4} from "../interfaces/ISCS4.sol";

/// @title MudarabahPool
/// @notice AAOIFI Sharia Standard #8 compliant Mudarabah implementation
/// @dev Manager-investor profit-sharing pool with NAV-based accounting
contract MudarabahPool is ISCS1, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    address public immutable manager;
    address public immutable mudarib;
    address public immutable capitalProvider;
    ISCS4 public immutable enforcement;
    
    uint256 public mudaribShareBps;
    uint256 public capitalProviderShareBps;
    uint256 public totalCapital;
    uint256 public deployedCapital;
    uint256 private nextDeploymentId;
    
    bool public isActive = true;
    bool public isLiquidating;

    mapping(uint256 => Deployment) public deployments;

    struct Deployment {
        address strategy;
        uint256 amount;
        bool active;
    }

    error Unauthorized();
    error PoolInactive();
    error PoolLiquidating();
    error InsufficientCapital();
    error InvalidAmount();

    modifier onlyManager() {
        if (msg.sender != manager) revert Unauthorized();
        _;
    }

    modifier onlyCapitalProvider() {
        if (msg.sender != capitalProvider) revert Unauthorized();
        _;
    }

    modifier whenActive() {
        if (!isActive) revert PoolInactive();
        if (isLiquidating) revert PoolLiquidating();
        _;
    }

    constructor(
        address _asset,
        address _manager,
        address _capitalProvider,
        uint256 _managerShareBps,
        uint256 _capitalProviderShareBps,
        address _enforcement,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        asset = IERC20(_asset);
        manager = _manager;
        mudarib = _manager;
        capitalProvider = _capitalProvider;
        mudaribShareBps = _managerShareBps;
        capitalProviderShareBps = _capitalProviderShareBps;
        enforcement = ISCS4(_enforcement);

        enforcement.validateProfitRatio(_managerShareBps, _capitalProviderShareBps);
    }

    function deposit(uint256 amount) external onlyCapitalProvider whenActive nonReentrant returns (uint256 shares) {
        if (amount == 0) revert InvalidAmount();
        
        uint256 supply = totalSupply();
        shares = supply == 0 ? amount : (amount * supply) / totalCapital;
        
        totalCapital += amount;
        _mint(capitalProvider, shares);
        asset.safeTransferFrom(capitalProvider, address(this), amount);
        
        emit CapitalDeposited(capitalProvider, amount, shares);
    }

    function withdraw(uint256 shares) external onlyCapitalProvider nonReentrant returns (uint256 amount) {
        if (shares == 0) revert InvalidAmount();
        
        amount = (shares * totalCapital) / totalSupply();
        if (amount > availableCapital()) revert InsufficientCapital();
        
        totalCapital -= amount;
        _burn(capitalProvider, shares);
        asset.safeTransfer(capitalProvider, amount);
        
        emit CapitalWithdrawn(capitalProvider, amount, shares);
    }

    function deployCapital(address strategy, uint256 amount) external onlyManager whenActive nonReentrant returns (uint256 deploymentId) {
        if (amount == 0 || amount > availableCapital()) revert InvalidAmount();
        
        enforcement.validateDeployment(amount, 0);
        
        deploymentId = nextDeploymentId++;
        deployments[deploymentId] = Deployment(strategy, amount, true);
        deployedCapital += amount;
        asset.safeTransfer(strategy, amount);
        
        emit CapitalDeployed(deploymentId, amount, strategy);
    }

    function returnCapital(uint256 deploymentId, uint256 returnedAmount) external nonReentrant {
        Deployment storage deployment = deployments[deploymentId];
        if (!deployment.active) revert InvalidAmount();
        
        int256 profitLoss = int256(returnedAmount) - int256(deployment.amount);
        deployment.active = false;
        deployedCapital -= deployment.amount;
        
        if (returnedAmount > 0) {
            asset.safeTransferFrom(msg.sender, address(this), returnedAmount);
        }
        
        emit CapitalReturned(deploymentId, returnedAmount, profitLoss);
    }

    function distributeProfits() external onlyManager nonReentrant {
        uint256 currentValue = asset.balanceOf(address(this)) + deployedCapital;
        if (currentValue <= totalCapital) return;
        
        uint256 profit = currentValue - totalCapital;
        uint256 managerAmount = (profit * mudaribShareBps) / 10000;
        uint256 providerAmount = profit - managerAmount;
        
        totalCapital += providerAmount;
        asset.safeTransfer(manager, managerAmount);
        
        emit ProfitsDistributed(providerAmount, managerAmount);
    }

    function claimProfit() external onlyManager nonReentrant returns (uint256 amount) {
        uint256 currentValue = asset.balanceOf(address(this)) + deployedCapital;
        if (currentValue <= totalCapital) return 0;
        
        uint256 profit = currentValue - totalCapital;
        amount = (profit * mudaribShareBps) / 10000;
        uint256 providerAmount = profit - amount;
        
        totalCapital += providerAmount;
        asset.safeTransfer(manager, amount);
        
        emit ProfitsDistributed(providerAmount, amount);
    }

    function recordLoss(uint256 amount) external onlyManager nonReentrant {
        if (amount == 0 || amount > totalCapital) revert InvalidAmount();
        
        totalCapital -= amount;
        
        emit LossAllocated(amount);
    }

    function terminate() external onlyCapitalProvider {
        isActive = false;
    }

    function availableCapital() public view returns (uint256) {
        return totalCapital - deployedCapital;
    }

    function getPoolInfo() external view returns (
        address _manager,
        address _capitalProvider,
        uint256 _managerShareBps,
        uint256 _providerShareBps,
        uint256 _totalCapital,
        uint256 _deployedCapital,
        bool _isActive
    ) {
        return (manager, capitalProvider, mudaribShareBps, capitalProviderShareBps, totalCapital, deployedCapital, isActive);
    }

    function calculateNAV() external view returns (uint256) {
        return totalCapital;
    }
}
