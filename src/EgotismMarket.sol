// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";

import { SubmissionVerifierMain } from "src/SubmissionVerifierMain.sol";

contract EgotismMarket {
    enum BountyStatus {
        EMPTY,
        PENDING,
        CANCELLED,
        FULFILLED
    }

    struct Bounty {
        uint256 nonceX;
        uint256 nonceY;
        uint256 reward;
        uint176 expiration;
        address poster;
        ISubmissionVerifier verifier;
        BountyStatus status;
        bytes constraints;
    }

    ISubmissionVerifier immutable public mainVerifier;
    Bounty[] public bounties;

    constructor (ISubmissionVerifier _mainVerifier) {
        mainVerifier = _mainVerifier;
    }

    function createBounty(
        uint256 nonceX,
        uint256 nonceY,
        uint256 reward,
        bytes calldata constraints
    ) external payable returns (uint256 bountyId) {
        // TODO
    }

    function fulfillBounty(
        uint256 bountyId,
        uint256 submission,
        address receiver
    ) external {
        // TODO
    }

    function cancelBounty(
        uint256 bountyId
    ) external {
        // TODO
    }
}
