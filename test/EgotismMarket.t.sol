// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { EllipticCurve } from "elliptic-curve-solidity/contracts/EllipticCurve.sol";
import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";
import { EgotismMarket } from "src/EgotismMarket.sol";
import { EgotismLib } from "src/EgotismLib.sol";

abstract contract Shared {
    // ROLES
    address constant POSTER = address(1);
    address constant SUBMITTER = address(2);
    address constant OWNER = address(3);

    // [1234]G
    uint256 constant NONCE_X = 102884003323827292915668239759940053105992008087520207150474896054185180420338;
    uint256 constant NONCE_Y = 49384988101491619794462775601349526588349137780292274540231125201115197157452;

    uint256 constant OWNER_ROYALTY = 100;  // 1%
    uint256 constant REWARD = 1 ether;
    uint256 constant FEE = (REWARD / 100_00) * OWNER_ROYALTY;
    uint256 constant TOTAL_MESSAGE_VALUE = REWARD + FEE;

    bytes CONSTRAINTS = abi.encode(true, true);
    bytes INVALID_CONSTRAINTS = abi.encode(true, false);
    bytes UNSATISFIED_CONSTRAINTS = abi.encode(false, true);

    // SUBMISSION_SALT and SUBMISSION are tied
    uint256 constant SUBMISSION_SALT = 1234;
    uint256 constant SUBMISSION = 65309379242442000436034975801177189427509424436662457510180963480106109506156;
}

contract Constructor is Test, Shared {
    EgotismMarket market;
    ISubmissionVerifier verifier;

    function setUp() public { 
        verifier = new SubmissionVerifierMock();
        market = new EgotismMarket(OWNER, OWNER_ROYALTY, verifier);
    }

    function test_owner() public {
        assertEq(market.owner(), OWNER, "Unexpected owner");
    }

    function test_ownerRoyalty() public {
        assertEq(market.ownerRoyalty(), OWNER_ROYALTY, "Unexpected owner royalty");
    }

    function test_MainVerifier() public {
        assertEq(address(market.mainVerifier()), address(verifier), "Unexpected main verifier");
    }
}

contract CreateBounty is Test, Shared {
    EgotismMarket market;
    ISubmissionVerifier mainVerifier;

    function setUp() public {
        mainVerifier = new SubmissionVerifierMock();
        market = new EgotismMarket(OWNER, OWNER_ROYALTY, mainVerifier);
    }

    function test_Positive() public {
        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.deal(POSTER, TOTAL_MESSAGE_VALUE);
        vm.prank(POSTER);

        uint256 EXPECTED_BOUNTY_ID = 0;

        vm.expectEmit();
        emit EgotismMarket.BountyCreated(
            EXPECTED_BOUNTY_ID,
            POSTER,
            mainVerifier,
            REWARD,
            EXPIRATION
        );

        (uint256 bountyId) = market.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            mainVerifier,
            CONSTRAINTS
        );

        (uint256 nonceX,
        uint256 nonceY,
        uint256 reward,
        uint176 expiration,
        address poster,
        ISubmissionVerifier verifier,
        EgotismMarket.BountyStatus status,
        bytes memory constraints) = market.bounties(bountyId);

        assertEq(nonceX, NONCE_X, "Unexpected nonceX");
        assertEq(nonceY, NONCE_Y, "Unexpected nonceY");
        assertEq(reward, REWARD, "Unexpected reward");
        assertEq(expiration, EXPIRATION, "Unexpected expiration");
        assertEq(poster, POSTER, "Unexpected poster");
        assertEq(address(verifier), address(mainVerifier), "Unexpected verifier");
        assertEq(uint8(status), uint8(EgotismMarket.BountyStatus.PENDING), "Unexpected status");
        assertEq(constraints, CONSTRAINTS, "Unexpected constraints");
    }

    function test_RevertWhen_InvalidExpiration() public {
        uint176 EXPIRATION = uint176(block.timestamp - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                EgotismLib.InvalidExpiration.selector,
                EXPIRATION
            )
        );
        vm.deal(POSTER, REWARD);
        vm.prank(POSTER);

        market.createBounty{ value: REWARD }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            mainVerifier,
            CONSTRAINTS
        );
    }

    function test_RevertWhen_InvalidNonce() public {
        uint256 badNonceX = 1234;
        uint256 badNonceY = 4567;

        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                EgotismLib.InvalidNonce.selector,
                badNonceX,
                badNonceY
            )
        );
        vm.deal(POSTER, REWARD);
        vm.prank(POSTER);

        market.createBounty{ value: REWARD }(
            badNonceX,
            badNonceY,
            REWARD,
            EXPIRATION,
            mainVerifier,
            CONSTRAINTS
        );
    }

    function test_RevertWhen_InvalidBountyReward() public {
        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                EgotismLib.InvalidBountyReward.selector,
                TOTAL_MESSAGE_VALUE,
                REWARD
            )
        );
        vm.deal(POSTER, REWARD);
        vm.prank(POSTER);

        market.createBounty{ value: REWARD }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            mainVerifier,
            CONSTRAINTS
        );
    }

    function test_RevertWhen_InvalidConstraints() public {
        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.expectRevert(EgotismLib.InvalidConstraints.selector);
        vm.deal(POSTER, REWARD);
        vm.prank(POSTER);

        market.createBounty{ value: REWARD }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            mainVerifier,
            INVALID_CONSTRAINTS
        );
    }
}

contract FulfillBounty is Test, Shared {
    uint256 constant START_TIMESTAMP = 1000;
    uint256 constant VALID_TIMESTAMP = 1500;
    uint256 constant EXPIRATION_TIMESTAMP = 2000;

    EgotismMarket market;
    ISubmissionVerifier mainVerifier;

    uint256 bountyId;

    function setUp() public {
        mainVerifier = new SubmissionVerifierMock();
        market = new EgotismMarket(OWNER, OWNER_ROYALTY, mainVerifier);

        vm.deal(POSTER, TOTAL_MESSAGE_VALUE);
        vm.prank(POSTER);
        vm.warp(START_TIMESTAMP);

        bountyId = market.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            uint176(EXPIRATION_TIMESTAMP),
            mainVerifier,
            CONSTRAINTS
        );

        vm.warp(VALID_TIMESTAMP);
    }

    function test_Positive() public {
        vm.deal(SUBMITTER, 0);

        vm.expectEmit();
        emit EgotismMarket.BountyFulfilled(
            bountyId,
            POSTER,
            SUBMITTER,
            REWARD,
            SUBMISSION
        );

        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);

        assertEq(SUBMITTER.balance, REWARD, "Incorrect reward given");
        (,,,,,,EgotismMarket.BountyStatus status,) = market.bounties(bountyId);
        assertEq(uint8(status), uint8(EgotismMarket.BountyStatus.FULFILLED), "Incorrect status update");
    }

    function test_RevertWhen_BountyNotPending_Fulfilled() public {
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
        vm.expectRevert(EgotismLib.BountyNotPending.selector);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
    }

    function test_RevertWhen_BountyNotPending_Cancelled() public {
        vm.prank(POSTER);
        vm.warp(EXPIRATION_TIMESTAMP);
        market.cancelBounty(bountyId);
        vm.expectRevert(EgotismLib.BountyNotPending.selector);
        vm.warp(VALID_TIMESTAMP);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
    }

    function test_RevertWhen_BountyExpired() public {
        vm.warp(EXPIRATION_TIMESTAMP);
        vm.expectRevert(EgotismLib.BountyExpired.selector);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
    }

    // need to find submission salt that makes deriveAddress fail
    function test_RevertWhen_InvalidSubmission_Derive() public {
        // TODO
    }

    function test_RevertWhen_InvalidSubmission_Constraints() public {
        vm.deal(POSTER, TOTAL_MESSAGE_VALUE);
        vm.prank(POSTER);
        vm.warp(START_TIMESTAMP);

        bountyId = market.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            uint176(EXPIRATION_TIMESTAMP),
            mainVerifier,
            UNSATISFIED_CONSTRAINTS
        );

        vm.warp(VALID_TIMESTAMP);
        vm.expectRevert(EgotismLib.InvalidSubmission.selector);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
    }

    function test_RevertWhen_RewardTransferFailure() public {
        UnpayableMock unpayable = new UnpayableMock();

        vm.expectRevert(EgotismLib.RewardTransferFailure.selector);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, address(unpayable));
    }
}

contract CancelBounty is Test, Shared {
    uint256 constant START_TIMESTAMP = 1000;
    uint256 constant VALID_TIMESTAMP = 2500;
    uint256 constant EXPIRATION_TIMESTAMP = 2000;

    EgotismMarket market;
    ISubmissionVerifier mainVerifier;

    uint256 bountyId;

    function setUp() public {
        mainVerifier = new SubmissionVerifierMock();
        market = new EgotismMarket(OWNER, OWNER_ROYALTY, mainVerifier);

        vm.deal(POSTER, TOTAL_MESSAGE_VALUE);
        vm.prank(POSTER);
        vm.warp(START_TIMESTAMP);

        bountyId = market.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            uint176(EXPIRATION_TIMESTAMP),
            mainVerifier,
            CONSTRAINTS
        );

        vm.warp(VALID_TIMESTAMP);
    }

    function test_Positive() public {
        vm.deal(POSTER, 0);
        vm.prank(POSTER);

        vm.expectEmit();
        emit EgotismMarket.BountyCancelled(
            bountyId,
            POSTER,
            REWARD
        );

        market.cancelBounty(bountyId);

        assertEq(POSTER.balance, REWARD, "Incorrect refund given");
        (,,,,,,EgotismMarket.BountyStatus status,) = market.bounties(bountyId);
        assertEq(uint8(status), uint8(EgotismMarket.BountyStatus.CANCELLED), "Incorrect status update");
    }

    function test_RevertWhen_Unauthorized() public {
        vm.expectRevert(EgotismLib.Unauthorized.selector);
        market.cancelBounty(bountyId);
    }

    function test_RevertWhen_BountyNotPending_Fulfilled() public {
        vm.warp(EXPIRATION_TIMESTAMP - 1);
        market.fulfillBounty(bountyId, SUBMISSION_SALT, SUBMITTER);
        vm.warp(VALID_TIMESTAMP);

        vm.expectRevert(EgotismLib.BountyNotPending.selector);
        vm.prank(POSTER);
        market.cancelBounty(bountyId);
    }

    function test_RevertWhen_BountyNotPending_Cancelled() public {
        vm.prank(POSTER);
        market.cancelBounty(bountyId);
        vm.expectRevert(EgotismLib.BountyNotPending.selector);
        vm.prank(POSTER);
        market.cancelBounty(bountyId);
    }

    function test_RevertWhen_BountyNotExpired() public {
        vm.warp(START_TIMESTAMP);
        vm.expectRevert(EgotismLib.BountyNotExpired.selector);
        vm.prank(POSTER);
        market.cancelBounty(bountyId);
    }

    function test_RevertWhen_RefundTransferFailure() public {
        UnpayableMock unpayable = new UnpayableMock();
        vm.expectRevert(EgotismLib.RefundTransferFailure.selector);
        unpayable.createBountyAndCancel(market, mainVerifier, vm);
    }
}

// constraints is a bool tuple,
// the first value mimics a constraint set that results valid verification for any result
// the second value mimics a constraint set that is in valid form
contract SubmissionVerifierMock is ISubmissionVerifier {
    function verify(
        address result,
        bytes calldata constraints
    ) external pure override returns (bool) {
        (bool constraintsSatisfied,) = abi.decode(constraints, (bool, bool));
        return constraintsSatisfied;
    }

    function verifyConstraints(
        bytes calldata constraints
    ) external pure override returns (bool) {
        (, bool constraintsValid) = abi.decode(constraints, (bool, bool));
        return constraintsValid;
    }
}

contract UnpayableMock is Shared {
    function createBountyAndCancel(
        EgotismMarket market, 
        ISubmissionVerifier mainVerifier,
        Vm vm
    ) external {
        vm.deal(address(this), TOTAL_MESSAGE_VALUE);

        uint176 EXPIRATION = uint176(block.timestamp + 1);
        uint256 bountyId = market.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            mainVerifier,
            CONSTRAINTS
        );

        vm.warp(EXPIRATION);
        market.cancelBounty(bountyId);
    }
}
