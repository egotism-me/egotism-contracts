// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";

import { SubmissionVerifierMain } from "src/SubmissionVerifierMain.sol";

import { EgotismLib } from "src/EgotismLib.sol";

// idea to explore: store only hash of constraints, but emit it full in events
// on other hand, it hurts interopability

// add owner fees later

// check against reentrancy attacks later (maybe worth to implement reentrancy just so it's less complex to analyze)

// think of possibility to "renew" bounty after expiration since submitting initial bounty costs a lot of gas
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
        uint176 expiration,
        ISubmissionVerifier verifier,
        bytes calldata constraints
    ) external payable returns (uint256 bountyId) {
        if (expiration <= block.timestamp) {
            revert EgotismLib.InvalidExpiration(expiration);
        }

        if (!EgotismLib.isNonceValid(nonceX, nonceY)) {
            revert EgotismLib.InvalidNonce(nonceX, nonceY);
        }

        if (reward != msg.value) {
            revert EgotismLib.InvalidBountyReward(reward, msg.value);
        }

        // might remove check for favour of gas?
        // and because reentrancy complexities
        if (!verifier.verifyConstraints(constraints)) {
            revert EgotismLib.InvalidConstraints();
        }

        bountyId = bounties.length;
        address poster = msg.sender;
        bounties.push(
            Bounty({
                nonceX: nonceX,
                nonceY: nonceY,
                reward: reward,
                expiration: expiration,
                poster: poster,
                verifier: verifier,
                status: BountyStatus.PENDING,
                constraints: constraints
            })
        );
        
        emit BountyCreated(bountyId, poster, verifier, reward, expiration);
    }

    function fulfillBounty(
        uint256 bountyId,
        uint256 submissionSalt,
        address receiver
    ) external {
        // if out of range reverts?
        Bounty memory bounty = bounties[bountyId];

        if (bounty.status != BountyStatus.PENDING) {
            revert EgotismLib.BountyNotPending();
        }

        if (bounty.expiration <= block.timestamp) {
            revert EgotismLib.BountyExpired();
        }

        // submission is dependant on receiver to prevent frontrunning
        uint256 submission = EgotismLib.deriveSubmission(
            submissionSalt,
            receiver
        );

        address result = EgotismLib.deriveAddress(
            bounty.nonceX,
            bounty.nonceY,
            submission
        );

        bool check = bounty.verifier.verify(
            result,
            bounty.constraints
        );

        if (!check) {
            revert EgotismLib.InvalidSubmission();
        }

        // important to first set status then send money
        bounties[bountyId].status = BountyStatus.FULFILLED;

        (bool success,) = receiver.call{ value: bounty.reward }("");
        if (!success) {
            revert EgotismLib.RewardTransferFailure();
        }

        emit BountyFulfilled(bountyId, bounty.poster, receiver, bounty.reward, submission);
    }

    function cancelBounty(
        uint256 bountyId
    ) external {
        // if out of range reverts?
        Bounty memory bounty = bounties[bountyId];

        if (bounty.status != BountyStatus.PENDING) {
            revert EgotismLib.BountyNotPending();
        }

        if (bounty.expiration < block.timestamp) {
            revert EgotismLib.BountyNotExpired();
        }

        bounties[bountyId].status = BountyStatus.CANCELLED;

        (bool success,) = bounty.poster.call{ value: bounty.reward }("");
        if (!success) {
            revert EgotismLib.RefundTransferFailure();
        }

        emit BountyCancelled(bountyId, bounty.poster, bounty.reward);
    }

    event BountyCreated(
        uint256 indexed id, 
        address indexed poster, 
        ISubmissionVerifier indexed verifier, 
        uint256 reward, 
        uint176 expiration
    );

    event BountyFulfilled(
        uint256 indexed id,
        address indexed poster,
        address indexed receiver,
        uint256 reward,
        uint256 submission
    );

    event BountyCancelled(
        uint256 indexed id,
        address indexed poster,
        uint256 reward
    );
}
