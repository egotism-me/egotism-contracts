// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface ISubmissionVerifier {
    // verify that result satisfies constraints
    function verify(
        address result,
        bytes calldata constraints
    ) external pure returns (bool);

    // verify that the constraints are formatted correctly (not necessarily feasible)
    function verifyConstraints(
        bytes calldata constraints
    ) external pure returns (bool);
}
