// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { ISubmissionVerifier } from "src/interfaces/ISubmissionVerifier.sol";

import { EgotismLib } from "src/EgotismLib.sol";

abstract contract SubmissionVerifierCore is ISubmissionVerifier {
    function verify(
        uint256 submission, 
        address result,
        address receiver,
        bytes calldata constraints
    ) public virtual view returns (bool) {
        if (address(uint160(submission >> 96)) != receiver) {
            revert EgotismLib.InvalidReceiver(receiver);
        }

        return false;
    }
}
