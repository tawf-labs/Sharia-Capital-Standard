// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISCS5} from "../interfaces/ISCS5.sol";

/// @title AAOIFIGovernance
/// @notice AAOIFI Governance Standard #3 compliance layer
/// @dev Integrates with ShariaBoard for compliance oversight
contract AAOIFIGovernance is Ownable {
    ISCS5 public shariaBoard;
    
    mapping(address => bool) public prohibitedAssets;
    mapping(address => AssetScreening) public assetScreening;
    
    uint256 public maxDebtRatio = 3300; // 33% max debt
    uint256 public maxInterestRatio = 3000; // 30% max interest income
    
    struct AssetScreening {
        bool screened;
        bool compliant;
        uint256 screenedAt;
        string reason;
    }

    event AssetProhibited(address indexed asset);
    event AssetPermitted(address indexed asset);
    event AssetScreened(address indexed asset, bool compliant, string reason);
    event RatioUpdated(string ratioType, uint256 newValue);

    error AssetIsProhibited();
    error AssetNotScreened();
    error RatioExceeded();

    constructor(address _shariaBoard) Ownable(msg.sender) {
        shariaBoard = ISCS5(_shariaBoard);
    }

    function prohibitAsset(address asset) external onlyOwner {
        prohibitedAssets[asset] = true;
        emit AssetProhibited(asset);
    }

    function permitAsset(address asset) external onlyOwner {
        prohibitedAssets[asset] = false;
        emit AssetPermitted(asset);
    }

    function screenAsset(
        address asset,
        bool compliant,
        string memory reason
    ) external onlyOwner {
        assetScreening[asset] = AssetScreening({
            screened: true,
            compliant: compliant,
            screenedAt: block.timestamp,
            reason: reason
        });
        
        emit AssetScreened(asset, compliant, reason);
    }

    function validateAsset(address asset) external view returns (bool) {
        if (prohibitedAssets[asset]) revert AssetIsProhibited();
        
        AssetScreening memory screening = assetScreening[asset];
        if (!screening.screened) revert AssetNotScreened();
        
        return screening.compliant;
    }

    function validateFinancialRatios(
        uint256 totalAssets,
        uint256 totalDebt,
        uint256 interestIncome
    ) external view returns (bool) {
        if (totalAssets == 0) return true;
        
        uint256 debtRatio = (totalDebt * 10000) / totalAssets;
        if (debtRatio > maxDebtRatio) revert RatioExceeded();
        
        uint256 interestRatio = (interestIncome * 10000) / totalAssets;
        if (interestRatio > maxInterestRatio) revert RatioExceeded();
        
        return true;
    }

    function setMaxDebtRatio(uint256 ratio) external onlyOwner {
        maxDebtRatio = ratio;
        emit RatioUpdated("debt", ratio);
    }

    function setMaxInterestRatio(uint256 ratio) external onlyOwner {
        maxInterestRatio = ratio;
        emit RatioUpdated("interest", ratio);
    }

    function setShariaBoard(address _shariaBoard) external onlyOwner {
        shariaBoard = ISCS5(_shariaBoard);
    }

    function getAssetScreening(address asset) external view returns (
        bool screened,
        bool compliant,
        uint256 screenedAt,
        string memory reason
    ) {
        AssetScreening memory screening = assetScreening[asset];
        return (screening.screened, screening.compliant, screening.screenedAt, screening.reason);
    }
}
