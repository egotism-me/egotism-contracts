// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";
import { EgotismLib } from "src/EgotismLib.sol";

contract SubmissionVerifierMain is ISubmissionVerifier {
    bytes4 public constant CONSTRAINT_PATTERN_SIG = 0x00000001;

    function verify(
        address result,
        bytes calldata constraints
    ) public pure returns (bool) {
        bytes[] memory constraintArray = abi.decode(constraints, (bytes[]));
        for (uint256 i = 0; i < constraintArray.length; i++) {
            bytes memory constraint = constraintArray[i];
            bytes4 signature = bytes4(constraint);

            if (signature == CONSTRAINT_PATTERN_SIG) {
                (, bytes20 mask, bytes20 pattern) = abi.decode(
                    constraint,
                    (bytes4, bytes20, bytes20)
                );

                bytes20 addressMasked = bytes20(result) & mask;
                if (addressMasked != pattern) {
                    return false;
                }
            } else {
                revert EgotismLib.InvalidConstraint(signature);
            }
        }

        return true;
    }

    // as of now, reverts for invalid encoding of a bytes[].
    // this still works since it will make the caller revert, but ideally, this should never revert
    function verifyConstraints(
        bytes calldata constraints
    ) external pure override returns (bool) {
        bytes[] memory constraintArray = abi.decode(constraints, (bytes[]));

        for (uint256 i = 0; i < constraintArray.length; i++) {
            bytes4 signature = bytes4(constraintArray[i]);

            // for now supports only pattern constraint
            if (signature != CONSTRAINT_PATTERN_SIG) {
                return false;
            }
        }

        return true;
    }
}
