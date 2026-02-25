// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISCS3} from "../interfaces/ISCS3.sol";
import {ISCS4} from "../interfaces/ISCS4.sol";

/// @title VaultEngine
/// @notice ERC-4626 tokenized vault with epoch-based accounting (based on AAOIFI standards)
/// @dev Multi-strategy vault with NAV calculation and performance tracking
contract VaultEngine is ISCS3, ERC4626, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    ISCS4 public immutable enforcement;
    
    uint256 public currentEpoch;
    uint256 public epochDuration = 7 days;
    uint256 public lastEpochTimestamp;
    uint256 public performanceFeeBps = 1000; // 10%
    uint256 public managementFeeBps = 200;   // 2%
    
    address[] public strategies;
    mapping(address => StrategyData) public strategyInfo;
    mapping(uint256 => EpochData) private _epochs;
    
    uint256 public totalDeployed;
    bool public isActive = true;

    struct StrategyData {
        bool active;
        uint256 allocation;
        uint256 deployed;
        uint256 totalReturns;
    }

    struct EpochData {
        uint256 startNAV;
        uint256 endNAV;
        uint256 deposits;
        uint256 withdrawals;
        uint256 performanceFee;
    }

    error Unauthorized();
    error VaultInactive();
    error InvalidStrategy();
    error InvalidAmount();
    error EpochNotEnded();

    modifier whenActive() {
        if (!isActive) revert VaultInactive();
        _;
    }

    constructor(
        address _asset,
        address _enforcement,
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(_asset)) ERC20(_name, _symbol) Ownable(msg.sender) {
        enforcement = ISCS4(_enforcement);
        lastEpochTimestamp = block.timestamp;
        _epochs[0].startNAV = 0;
    }

    function deposit(uint256 assets, address receiver) public override(ERC4626, IERC4626) whenActive nonReentrant returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
        _epochs[currentEpoch].deposits += assets;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override(ERC4626, IERC4626) nonReentrant returns (uint256 shares) {
        shares = super.withdraw(assets, receiver, owner);
        _epochs[currentEpoch].withdrawals += assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function addStrategy(address strategy, uint256 allocationBps) external onlyOwner {
        if (strategy == address(0)) revert InvalidStrategy();
        
        strategies.push(strategy);
        strategyInfo[strategy] = StrategyData({
            active: true,
            allocation: allocationBps,
            deployed: 0,
            totalReturns: 0
        });
        
        emit StrategyAdded(strategy, allocationBps);
    }

    function removeStrategy(address strategy) external onlyOwner {
        StrategyData storage info = strategyInfo[strategy];
        if (info.deployed > 0) revert InvalidAmount();
        
        info.active = false;
        emit StrategyRemoved(strategy);
    }

    function deployToStrategy(address strategy, uint256 amount) external onlyOwner whenActive nonReentrant {
        StrategyData storage info = strategyInfo[strategy];
        if (!info.active) revert InvalidStrategy();
        if (amount == 0 || amount > totalAssets() - totalDeployed) revert InvalidAmount();
        
        enforcement.validateDeployment(amount, 0);
        
        info.deployed += amount;
        totalDeployed += amount;
        
        IERC20(asset()).safeTransfer(strategy, amount);
    }

    function recallFromStrategy(address strategy, uint256 amount) external onlyOwner nonReentrant {
        StrategyData storage info = strategyInfo[strategy];
        if (amount > info.deployed) revert InvalidAmount();
        
        info.deployed -= amount;
        totalDeployed -= amount;
        
        IERC20(asset()).safeTransferFrom(strategy, address(this), amount);
    }

    function recordStrategyReturn(address strategy, uint256 returnAmount) external onlyOwner {
        StrategyData storage info = strategyInfo[strategy];
        if (!info.active) revert InvalidStrategy();
        
        info.totalReturns += returnAmount;
    }

    function _startNewEpoch() internal {
        if (block.timestamp < lastEpochTimestamp + epochDuration) revert EpochNotEnded();
        
        uint256 nav = calculateNAV();
        _epochs[currentEpoch].endNAV = nav;
        
        // Profit = ending NAV - starting NAV - net deposits
        uint256 startNAV = _epochs[currentEpoch].startNAV;
        uint256 netDeposits = _epochs[currentEpoch].deposits - _epochs[currentEpoch].withdrawals;
        
        uint256 profit = 0;
        if (nav > startNAV + netDeposits) {
            profit = nav - startNAV - netDeposits;
        }
        
        uint256 perfFee = (profit * performanceFeeBps) / 10000;
        _epochs[currentEpoch].performanceFee = perfFee;
        
        currentEpoch++;
        lastEpochTimestamp = block.timestamp;
        _epochs[currentEpoch].startNAV = nav - perfFee;
        
        emit EpochFinalized(currentEpoch - 1, nav);
    }

    function startNewEpoch() external onlyOwner {
        _startNewEpoch();
    }

    function startEpoch() external onlyOwner {
        _startNewEpoch();
    }

    function finalizeEpoch() external onlyOwner {
        _startNewEpoch();
    }

    function rebalanceStrategies(address[] calldata, uint256[] calldata) external pure {
        revert("Not implemented");
    }

    function epochs(uint256 epochId) external view returns (Epoch memory) {
        EpochData memory data = _epochs[epochId];
        return Epoch({
            startTime: lastEpochTimestamp,
            endTime: lastEpochTimestamp + epochDuration,
            startingNAV: data.startNAV,
            endingNAV: data.endNAV,
            finalized: data.endNAV > 0
        });
    }

    function calculateNAV() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + totalDeployed;
    }

    function getEpochData(uint256 epoch) external view returns (
        uint256 startNAV,
        uint256 endNAV,
        uint256 deposits,
        uint256 withdrawals,
        uint256 performanceFee
    ) {
        EpochData memory data = _epochs[epoch];
        return (data.startNAV, data.endNAV, data.deposits, data.withdrawals, data.performanceFee);
    }

    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    function getStrategyInfo(address strategy) external view returns (
        bool active,
        uint256 allocation,
        uint256 deployed,
        uint256 totalReturns
    ) {
        StrategyData memory info = strategyInfo[strategy];
        return (info.active, info.allocation, info.deployed, info.totalReturns);
    }

    function setPerformanceFee(uint256 feeBps) external onlyOwner {
        if (feeBps > 2000) revert InvalidAmount(); // Max 20%
        performanceFeeBps = feeBps;
    }

    function setEpochDuration(uint256 duration) external onlyOwner {
        if (duration < 1 days) revert InvalidAmount();
        epochDuration = duration;
    }

    function pause() external onlyOwner {
        isActive = false;
    }

    function unpause() external onlyOwner {
        isActive = true;
    }

    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        return calculateNAV();
    }
}
