// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { EgotismMarket } from "src/EgotismMarket.sol";
import { SubmissionVerifierMain } from "src/SubmissionVerifierMain.sol";
import { EgotismLib } from "src/EgotismLib.sol";

contract IntegrationMain1 is Test {
    address constant MARKET_OWNER = address(1);
    address constant BOUNTY_POSTER = address(2);
    address constant BOUNTY_PROVIDER = address(3);

    uint256 constant OWNER_ROYALTY = 100;  // %1

    // [4]G
    uint256 constant NONCE = 4;
    uint256 constant NONCE_X = 103388573995635080359749164254216598308788835304023601477803095234286494993683;
    uint256 constant NONCE_Y = 37057141145242123013015316630864329550140216928701153669873286428255828810018;

    uint256 constant REWARD = 1 ether;
    uint256 constant FEE = (REWARD / 100_00) * OWNER_ROYALTY;
    uint256 constant TOTAL_MESSAGE_VALUE = REWARD + FEE;
    uint176 constant EXPIRATION = 2 ** 175;  // unreasonably large

    // expected address and submission are contingent on submission salt, nonce, and receiver address
    // (the receiver address in this case is the bounty provider)
    uint256 constant SUBMISSION_SALT = 1234;
    uint256 constant EXPECTED_SUBMISSION = 43647712108221077992635586596014271888847995781122858281467450162807062677622;
    address constant EXPECTED_ADDRESS = 0x525D624a248432C11a291d4FD2C285FE4DC9631c;

    function test_IntegrationMain1() public {
        // practically same as egotism market tests but not using mocks
        SubmissionVerifierMain submissionVerifierMain = new SubmissionVerifierMain();
        EgotismMarket egotismMarket = new EgotismMarket(MARKET_OWNER, OWNER_ROYALTY, submissionVerifierMain);

        //
        // POSTER PART
        //

        bytes20 mask = hex"FFFF";
        bytes20 pattern = hex"525D";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        vm.prank(BOUNTY_POSTER);
        vm.deal(BOUNTY_POSTER, TOTAL_MESSAGE_VALUE);
        uint256 bountyId = egotismMarket.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            submissionVerifierMain,
            abi.encode(constraints)
        );

        //
        // SUBMITTER PART
        //

        vm.expectEmit(true, true, true, true);
        emit EgotismMarket.BountyFulfilled(
            bountyId,
            BOUNTY_POSTER,
            BOUNTY_PROVIDER,
            REWARD,
            EXPECTED_SUBMISSION
        );
        vm.prank(BOUNTY_PROVIDER);
        egotismMarket.fulfillBounty(
            bountyId,
            SUBMISSION_SALT,
            BOUNTY_PROVIDER
        );

        uint256 resultScalar = mulmod(NONCE, EXPECTED_SUBMISSION, EgotismLib.SECP256K1_ORDER);
        address resultAddress = EgotismLib.deriveAddress(EgotismLib.SECP256K1_GX, EgotismLib.SECP256K1_GY, resultScalar);

        assertEq(resultAddress, EXPECTED_ADDRESS, "mismatching addresses");
    }
}
