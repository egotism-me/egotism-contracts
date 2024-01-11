// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { EllipticCurve } from "elliptic-curve-solidity/contracts/EllipticCurve.sol";

library EgotismLib {
    uint256 public constant SECP256K1_GX =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant SECP256K1_GY =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant SECP256K1_AA = 0;
    uint256 public constant SECP256K1_BB = 7;
    uint256 public constant SECP256K1_PP =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    function isNonceValid(
        uint256 nonceX,
        uint256 nonceY
    ) internal pure returns (bool) {
        return EllipticCurve.isOnCurve(nonceX, nonceY, SECP256K1_AA, SECP256K1_BB, SECP256K1_PP);
    }

    function deriveAddress(
        uint256 nonceX,
        uint256 nonceY,
        uint256 submission
    ) internal pure returns (address) {
        (uint256 x, uint256 y) = EllipticCurve.ecMul(submission, nonceX, nonceY, SECP256K1_AA, SECP256K1_PP);

        return address(uint160(uint256(keccak256(abi.encode(x, y)))));
    }

    error InvalidReceiver(address receiver);

    error InvalidConstraint(bytes4 signature);
}
