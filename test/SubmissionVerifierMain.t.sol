// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { SubmissionVerifierMain } from "src/SubmissionVerifierMain.sol";

contract Verify is Test {
    SubmissionVerifierMain submissionVerifierMain;

    function setUp() public {
        submissionVerifierMain = new SubmissionVerifierMain();
    }

    function test_Positive1() public view {
        address result = address(0x1234560000000000000000000000000000000000);
        bytes20 mask = hex"FFFF";
        bytes20 pattern = hex"1234";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(success);
    }

    function test_Positive2() public view {
        address result = address(0x1234560000000000000000000000000000000099);
        bytes20 mask = hex"FFFF0000000000000000000000000000000000FF";
        bytes20 pattern = hex"1234000000000000000000000000000000000099";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(success);
    }

    function test_Positive3() public view {
        address result = address(0x1234560000000000000000000000000000000099);
        bytes20 mask = hex"FFFF0000000000000000000000000000000000FF";
        bytes20 pattern = hex"1234770000000000000000000000000000000099";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(success);
    }

    function test_Negative1() public view {
        address result = address(0x1299560000000000000000000000000000000000);
        bytes20 mask = hex"FFFF";
        bytes20 pattern = hex"1234";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(!success);
    }

    function test_Negative2() public view {
        address result = address(0x1234560000000000000000000000000000000098);
        bytes20 mask = hex"FFFF0000000000000000000000000000000000FF";
        bytes20 pattern = hex"1234000000000000000000000000000000000099";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(!success);
    }

    function test_Negative3() public view {
        address result = address(0x1234560000000000000000000000000000000099);
        bytes20 mask = hex"FFFFFF00000000000000000000000000000000FF";
        bytes20 pattern = hex"1234770000000000000000000000000000000099";

        bytes memory constraint = abi.encode(
            submissionVerifierMain.CONSTRAINT_PATTERN_SIG(),
            mask,
            pattern
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        bool success = submissionVerifierMain.verify(
            result,
            abi.encode(constraints)
        );

        assert(!success);
    }
}

contract VerifyConstraints is Test {
    SubmissionVerifierMain submissionVerifierMain;

    function setUp() public {
        submissionVerifierMain = new SubmissionVerifierMain();
    }
}
