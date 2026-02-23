// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISCS5} from "../interfaces/ISCS5.sol";

/// @title ShariaBoard
/// @notice Sharia Supervisory Board (SSB) implementation per AAOIFI Governance Standard #3
/// @dev Multi-signature approval system for Sharia compliance oversight
contract ShariaBoard is ISCS5, Ownable {
    enum ProposalType {
        INVESTMENT,
        PARAMETER_CHANGE,
        ASSET_SCREENING,
        GENERAL
    }

    uint256 public requiredApprovals;
    uint256 public memberCount;
    
    mapping(address => bool) public isSSBMember;
    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => mapping(address => bool)) public hasApproved;
    
    address[] public members;
    bytes32[] public proposalIds;

    struct Proposal {
        string description;
        address target;
        bytes data;
        uint256 approvals;
        bool executed;
        ProposalType proposalType;
    }

    error NotSSBMember();
    error ProposalNotApproved();
    error ProposalAlreadyExecuted();
    error AlreadyApproved();
    error InvalidMember();

    event ProposalSubmitted(bytes32 indexed proposalId, address indexed submitter, string description);
    event ProposalApproved(bytes32 indexed proposalId, address indexed approver);
    event ProposalExecuted(bytes32 indexed proposalId, bool success);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    modifier onlySSBMember() {
        if (!isSSBMember[msg.sender]) revert NotSSBMember();
        _;
    }

    constructor(address[] memory _members, uint256 _requiredApprovals) Ownable(msg.sender) {
        if (_requiredApprovals == 0 || _requiredApprovals > _members.length) {
            revert InvalidMember();
        }

        requiredApprovals = _requiredApprovals;
        
        for (uint256 i = 0; i < _members.length; i++) {
            if (_members[i] == address(0)) revert InvalidMember();
            isSSBMember[_members[i]] = true;
            members.push(_members[i]);
        }
        
        memberCount = _members.length;
    }

    function submitProposal(
        string memory description,
        address target,
        bytes memory data,
        ProposalType proposalType
    ) external onlySSBMember returns (bytes32 proposalId) {
        proposalId = keccak256(abi.encodePacked(description, target, data, block.timestamp));
        
        proposals[proposalId] = Proposal({
            description: description,
            target: target,
            data: data,
            approvals: 0,
            executed: false,
            proposalType: proposalType
        });
        
        proposalIds.push(proposalId);
        
        emit ProposalSubmitted(proposalId, msg.sender, description);
    }

    function approveProposal(bytes32 proposalId) external onlySSBMember {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (hasApproved[proposalId][msg.sender]) revert AlreadyApproved();
        
        hasApproved[proposalId][msg.sender] = true;
        proposal.approvals++;
        
        emit ProposalApproved(proposalId, msg.sender);
    }

    function executeProposal(bytes32 proposalId) external onlySSBMember returns (bool success) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.approvals < requiredApprovals) revert ProposalNotApproved();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        
        proposal.executed = true;
        
        (success,) = proposal.target.call(proposal.data);
        
        emit ProposalExecuted(proposalId, success);
    }

    function addMember(address member) external onlyOwner {
        if (member == address(0) || isSSBMember[member]) revert InvalidMember();
        
        isSSBMember[member] = true;
        members.push(member);
        memberCount++;
        
        emit MemberAdded(member);
    }

    function removeMember(address member) external onlyOwner {
        if (!isSSBMember[member]) revert InvalidMember();
        
        isSSBMember[member] = false;
        memberCount--;
        
        emit MemberRemoved(member);
    }

    function setRequiredApprovals(uint256 _requiredApprovals) external onlyOwner {
        if (_requiredApprovals == 0 || _requiredApprovals > memberCount) {
            revert InvalidMember();
        }
        requiredApprovals = _requiredApprovals;
    }

    function getProposal(bytes32 proposalId) external view returns (
        string memory description,
        address target,
        uint256 approvals,
        bool executed,
        ProposalType proposalType
    ) {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.target,
            proposal.approvals,
            proposal.executed,
            proposal.proposalType
        );
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function getProposalCount() external view returns (uint256) {
        return proposalIds.length;
    }

    // ISCS5 interface implementations
    function MIN_SSB_MEMBERS() external pure returns (uint256) {
        return 3;
    }

    function SSB_QUORUM() external view returns (uint256) {
        return requiredApprovals;
    }

    function ssbMemberCount() external view returns (uint256) {
        return memberCount;
    }

    function addSSBMember(address member) external {
        if (member == address(0) || isSSBMember[member]) revert InvalidMember();
        
        isSSBMember[member] = true;
        members.push(member);
        memberCount++;
        
        emit SSBMemberAdded(member);
    }

    function removeSSBMember(address member) external {
        if (!isSSBMember[member]) revert InvalidMember();
        
        isSSBMember[member] = false;
        memberCount--;
        
        emit SSBMemberRemoved(member);
    }

    function approveStrategy(bytes32 strategyHash) external onlySSBMember {
        Proposal storage proposal = proposals[strategyHash];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (hasApproved[strategyHash][msg.sender]) revert AlreadyApproved();
        
        hasApproved[strategyHash][msg.sender] = true;
        proposal.approvals++;
        
        emit StrategyApproved(strategyHash, proposal.approvals);
    }

    function isProposalApproved(bytes32 proposalId) external view returns (bool) {
        return proposals[proposalId].approvals >= requiredApprovals;
    }

    function isStrategyApproved(bytes32 strategyHash) external view returns (bool) {
        return proposals[strategyHash].approvals >= requiredApprovals;
    }

    function validateAsset(address) external pure returns (bool, string memory) {
        return (true, "");
    }

    function checkFinancialRatios(FinancialRatios calldata ratios) external pure returns (bool, string memory) {
        if (ratios.totalAssets == 0) return (true, "");
        
        uint256 debtRatio = (ratios.interestBearingDebt * 10000) / ratios.totalAssets;
        if (debtRatio > 3300) return (false, "Debt ratio exceeds 33%");
        
        uint256 interestRatio = (ratios.interestIncome * 10000) / ratios.totalIncome;
        if (interestRatio > 500) return (false, "Interest income exceeds 5%");
        
        return (true, "");
    }
}
