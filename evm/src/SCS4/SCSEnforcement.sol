// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISCS4} from "../interfaces/ISCS4.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SCSEnforcement
 * @notice Non-Guaranteed Return Enforcement Layer
 * @dev Validates AAOIFI compliance rules for all SCS contracts
 */
contract SCSEnforcement is ISCS4, Ownable {
    uint256 private constant BPS_DENOMINATOR = 10000;
    uint256 private constant MAX_DEBT_RATIO_BPS = 3000; // 30%
    uint256 private constant MAX_INTEREST_INCOME_RATIO_BPS = 500; // 5%

    mapping(address => bool) private _compliantContracts;
    mapping(address => uint8) private _contractTypes;

    error GuaranteedReturnProhibited();
    error InvalidProfitRatio();
    error InvalidLossAllocation();
    error ContractNotRegistered();
    error AlreadyRegistered();

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc ISCS4
    function validateDeployment(uint256 amount, uint256 expectedReturn)
        external
        pure
        returns (ValidationResult memory result)
    {
        if (expectedReturn != 0) {
            return ValidationResult({isCompliant: false, reason: "Guaranteed returns prohibited by AAOIFI"});
        }
        if (amount == 0) {
            return ValidationResult({isCompliant: false, reason: "Deployment amount must be greater than zero"});
        }
        return ValidationResult({isCompliant: true, reason: ""});
    }

    /// @inheritdoc ISCS4
    function validateProfitRatio(uint256 capitalShareBps, uint256 mudaribShareBps)
        external
        pure
        returns (ValidationResult memory result)
    {
        if (capitalShareBps + mudaribShareBps != BPS_DENOMINATOR) {
            return ValidationResult({isCompliant: false, reason: "Profit shares must sum to 100%"});
        }
        if (capitalShareBps == 0 || mudaribShareBps == 0) {
            return ValidationResult({isCompliant: false, reason: "Both parties must receive profit share"});
        }
        return ValidationResult({isCompliant: true, reason: ""});
    }

    /// @inheritdoc ISCS4
    function validateLossAllocation(
        uint256 partnerCapital,
        uint256 totalCapital,
        uint256 partnerLoss,
        uint256 totalLoss
    ) external pure returns (ValidationResult memory result) {
        if (totalCapital == 0 || totalLoss == 0) {
            return ValidationResult({isCompliant: true, reason: ""});
        }

        uint256 expectedLoss = (partnerCapital * totalLoss) / totalCapital;
        
        // Allow 1 wei tolerance for rounding
        uint256 diff = partnerLoss > expectedLoss ? partnerLoss - expectedLoss : expectedLoss - partnerLoss;
        if (diff > 1) {
            return ValidationResult({
                isCompliant: false,
                reason: "Loss allocation must be proportional to capital (AAOIFI Sharia #12)"
            });
        }
        
        return ValidationResult({isCompliant: true, reason: ""});
    }

    /// @inheritdoc ISCS4
    function isCompliantContract(address contractAddress) external view returns (bool) {
        return _compliantContracts[contractAddress];
    }

    /// @inheritdoc ISCS4
    function registerContract(address contractAddress, uint8 scsType) external onlyOwner {
        if (_compliantContracts[contractAddress]) revert AlreadyRegistered();
        if (scsType == 0 || scsType > 5) revert InvalidProfitRatio();
        
        _compliantContracts[contractAddress] = true;
        _contractTypes[contractAddress] = scsType;
        
        emit ContractRegistered(contractAddress, scsType);
    }

    /// @inheritdoc ISCS4
    function deregisterContract(address contractAddress) external onlyOwner {
        if (!_compliantContracts[contractAddress]) revert ContractNotRegistered();
        
        _compliantContracts[contractAddress] = false;
        delete _contractTypes[contractAddress];
        
        emit ContractDeregistered(contractAddress);
    }

    /// @notice Get contract type
    function getContractType(address contractAddress) external view returns (uint8) {
        return _contractTypes[contractAddress];
    }
}
