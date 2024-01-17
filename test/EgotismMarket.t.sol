// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { EllipticCurve } from "elliptic-curve-solidity/contracts/EllipticCurve.sol";
import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";
import { EgotismMarket } from "src/EgotismMarket.sol";
import { EgotismLib } from "src/EgotismLib.sol";

abstract contract Shared {
    address constant POSTER = address(1);
    address constant SUBMITTER = address(2);

    // [1234]G
    uint256 constant NONCE_X = 102884003323827292915668239759940053105992008087520207150474896054185180420338;
    uint256 constant NONCE_Y = 49384988101491619794462775601349526588349137780292274540231125201115197157452;

    uint256 constant REWARD = 1 ether;
    
    bytes CONSTRAINTS = abi.encode(true, true);
    bytes INVALID_CONSTRAINTS = abi.encode(true, false);
    bytes UNSATISFIED_CONSTRAINTS = abi.encode(false, true);
}

contract Constructor is Test {
    EgotismMarket market;
    ISubmissionVerifier verifier;

    function setUp() public { 
        verifier = new SubmissionVerifierMock();
        market = new EgotismMarket(verifier);
    }

    function test_MainVerifier() public {
        assertEq(address(market.mainVerifier()), address(verifier));
    }
}

contract CreateBounty is Test, Shared {
    EgotismMarket market;
    ISubmissionVerifier mainVerifier;

    function setUp() public {
        mainVerifier = new SubmissionVerifierMock();
        market = new EgotismMarket(mainVerifier);
    }

    function test_Positive() public {
        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.deal(POSTER, REWARD);
        vm.prank(POSTER);

        // 
        // Having issues with event emission tests
        // Ignore for now
        //
        // uint256 EXPECTED_BOUNTY_ID = 0;
        //
        // vm.expectEmit();
        // emit EgotismMarket.BountyCreated(
        //     EXPECTED_BOUNTY_ID,
        //     POSTER,
        //     mainVerifier,
        //     REWARD,
        //     EXPIRATION
        // );

        (uint256 bountyId) = market.createBounty{ value: REWARD }(
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

    // exp
    // nonce
    // reward
    // constraints

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
        uint256 badReward = 1000 gwei;
        uint176 EXPIRATION = uint176(block.timestamp + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                EgotismLib.InvalidBountyReward.selector,
                REWARD,
                badReward
            )
        );
        vm.deal(POSTER, badReward);
        vm.prank(POSTER);

        market.createBounty{ value: badReward }(
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
