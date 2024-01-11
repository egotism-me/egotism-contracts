// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface ISubmissionVerifier {
    // verify that submission is related to receiver
    // and that result satisfies constraints
    function verify(
        uint256 submission, 
        address result,
        address receiver,
        bytes calldata constraints
    ) external view returns (bool);

    // verify that the constraints are formatted correctly (not necessarily feasible)
    function verifyConstraints(
        bytes calldata constraints
    ) external pure returns (bool);
}
