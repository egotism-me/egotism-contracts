// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { EgotismLib } from "src/EgotismLib.sol";
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

    function test_RevertWhen_InvalidConstraint() public {
        bytes4 INVALID_SIG = 0x12345678;
        bytes memory constraint = abi.encode(
            INVALID_SIG,
            bytes20(0),
            bytes20(0)
        );

        bytes[] memory constraints = new bytes[](1);
        constraints[0] = constraint;

        vm.expectRevert(
            abi.encodeWithSelector(
                EgotismLib.InvalidConstraint.selector,
                INVALID_SIG
            )
        );

        submissionVerifierMain.verify(
            address(0),
            abi.encode(constraints)
        );
    }
}

contract VerifyConstraints is Test {
    SubmissionVerifierMain submissionVerifierMain;

    function setUp() public {
        submissionVerifierMain = new SubmissionVerifierMain();
    }
}
