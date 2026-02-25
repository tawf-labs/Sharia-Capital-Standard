// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISCS2} from "../interfaces/ISCS2.sol";
import {ISCS4} from "../interfaces/ISCS4.sol";

/// @title MusharakahPool
/// @notice Joint venture pool based on AAOIFI Sharia Standard #12
/// @dev Multi-partner profit-sharing with proportional loss allocation
contract MusharakahPool is ISCS2, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    ISCS4 public immutable enforcement;
    
    address[] public partnerList;
    mapping(address => PartnerData) public partnerInfo;
    
    uint256 public totalCapital;
    uint256 public deployedCapital;
    bool public isActive = true;

    struct PartnerData {
        uint256 capitalContributed;
        uint256 profitShareBps;
        bool isPartner;
    }

    error Unauthorized();
    error PoolInactive();
    error InvalidAmount();
    error InvalidPartner();
    error InvalidProfitShares();

    modifier onlyPartner() {
        if (!partnerInfo[msg.sender].isPartner) revert Unauthorized();
        _;
    }

    modifier whenActive() {
        if (!isActive) revert PoolInactive();
        _;
    }

    constructor(
        address _asset,
        address[] memory _partners,
        uint256[] memory _profitSharesBps,
        address _enforcement,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        if (_partners.length != _profitSharesBps.length || _partners.length == 0) {
            revert InvalidPartner();
        }

        asset = IERC20(_asset);
        enforcement = ISCS4(_enforcement);

        uint256 totalProfitShare;
        for (uint256 i = 0; i < _partners.length; i++) {
            if (_partners[i] == address(0)) revert InvalidPartner();
            
            partnerList.push(_partners[i]);
            partnerInfo[_partners[i]] = PartnerData({
                capitalContributed: 0,
                profitShareBps: _profitSharesBps[i],
                isPartner: true
            });
            
            totalProfitShare += _profitSharesBps[i];
        }

        if (totalProfitShare != 10000) revert InvalidProfitShares();
    }

    function contributeCapital(uint256 amount) external onlyPartner whenActive nonReentrant returns (uint256 shares) {
        if (amount == 0) revert InvalidAmount();
        
        PartnerData storage partner = partnerInfo[msg.sender];
        
        uint256 supply = totalSupply();
        shares = supply == 0 ? amount : (amount * supply) / totalCapital;
        
        partner.capitalContributed += amount;
        totalCapital += amount;
        
        _mint(msg.sender, shares);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        emit PartnerAdded(msg.sender, amount, partner.profitShareBps);
    }

    function withdrawCapital(uint256 shares) external onlyPartner nonReentrant returns (uint256 amount) {
        if (shares == 0) revert InvalidAmount();
        
        amount = (shares * totalCapital) / totalSupply();
        if (amount > availableCapital()) revert InvalidAmount();
        
        PartnerData storage partner = partnerInfo[msg.sender];
        uint256 capitalReduction = (amount * partner.capitalContributed) / totalCapital;
        partner.capitalContributed -= capitalReduction;
        totalCapital -= amount;
        
        _burn(msg.sender, shares);
        asset.safeTransfer(msg.sender, amount);
        
        emit PartnerRemoved(msg.sender, amount);
    }

    function deployCapital(address strategy, uint256 amount) external onlyPartner whenActive nonReentrant {
        if (amount == 0 || amount > availableCapital()) revert InvalidAmount();
        
        enforcement.validateDeployment(amount, 0);
        
        deployedCapital += amount;
        asset.safeTransfer(strategy, amount);
    }

    function returnCapital(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        
        deployedCapital -= amount;
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    function distributeProfits() external onlyPartner nonReentrant {
        uint256 currentValue = asset.balanceOf(address(this)) + deployedCapital;
        if (currentValue <= totalCapital) return;
        
        uint256 totalProfit = currentValue - totalCapital;
        
        for (uint256 i = 0; i < partnerList.length; i++) {
            address partner = partnerList[i];
            uint256 profitShare = (totalProfit * partnerInfo[partner].profitShareBps) / 10000;
            
            if (profitShare > 0) {
                totalCapital += profitShare;
                partnerInfo[partner].capitalContributed += profitShare;
                emit ProfitDistributed(partner, profitShare);
            }
        }
    }

    function allocateLoss(uint256 loss) external onlyPartner nonReentrant {
        if (loss == 0 || loss > totalCapital) revert InvalidAmount();
        
        for (uint256 i = 0; i < partnerList.length; i++) {
            address partner = partnerList[i];
            PartnerData storage info = partnerInfo[partner];
            
            uint256 partnerLoss = (loss * info.capitalContributed) / totalCapital;
            info.capitalContributed -= partnerLoss;
            
            emit LossAllocated(partner, partnerLoss);
        }
        
        totalCapital -= loss;
    }

    function terminate() external onlyPartner {
        isActive = false;
    }

    function addPartner(address, uint256, uint256) external pure {
        revert("Not supported - partners set at creation");
    }

    function removePartner(address) external pure {
        revert("Not supported - use withdrawCapital");
    }

    function distributeProfit(uint256) external pure {
        revert("Use distributeProfits instead");
    }

    function claimProfit() external pure returns (uint256) {
        revert("Use distributeProfits instead");
    }

    function partners(address partner) external view returns (Partner memory) {
        PartnerData memory data = partnerInfo[partner];
        return Partner({
            capitalContribution: data.capitalContributed,
            profitShareBps: data.profitShareBps,
            active: data.isPartner
        });
    }

    function partnerCount() external view returns (uint256) {
        return partnerList.length;
    }

    function availableCapital() public view returns (uint256) {
        return totalCapital - deployedCapital;
    }

    function getPartners() external view returns (address[] memory) {
        return partnerList;
    }

    function getPartnerInfo(address partner) external view returns (
        uint256 capitalContributed,
        uint256 profitShareBps,
        uint256 shares
    ) {
        PartnerData memory info = partnerInfo[partner];
        return (info.capitalContributed, info.profitShareBps, balanceOf(partner));
    }

    function calculateNAV() external view returns (uint256) {
        return totalCapital;
    }
}
