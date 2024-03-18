// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import { EgotismMarket } from "src/EgotismMarket.sol";
import { SubmissionVerifierMain } from "src/SubmissionVerifierMain.sol";
import { EgotismLib } from "src/EgotismLib.sol";

contract CreateBountyScript is Script {
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

    function run() external {
        // first private key from default anvil mneumonic:
        // Mnemonic:          test test test test test test test test test test test junk
        // Derivation path:   m/44'/60'/0'/0/
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

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
        vm.stopBroadcast();

        // second private key from default anvil mneumonic:
        // Mnemonic:          test test test test test test test test test test test junk
        // Derivation path:   m/44'/60'/0'/0/
        uint256 providerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        vm.startBroadcast(providerPrivateKey);

        egotismMarket.createBounty{ value: TOTAL_MESSAGE_VALUE }(
            NONCE_X,
            NONCE_Y,
            REWARD,
            EXPIRATION,
            submissionVerifierMain,
            abi.encode(constraints)
        );

        vm.stopBroadcast();
    }
}
