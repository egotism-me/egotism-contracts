#!/bin/bash

# The error code you're looking for
error_code="b69f5e4e"

# Array of your custom Solidity errors
declare -a custom_errors=(
    "InvalidConstraint(bytes4)"
    "InvalidConstraints()"
    "InvalidNonce(uint256,uint256)"
    "InvalidExpiration(uint176)"
    "InvalidBountyReward(uint256,uint256)"
    "InvalidSubmission()"
    "BountyNotPending()"
    "BountyExpired()"
    "BountyNotExpired()"
    "RewardTransferFailure()"
    "Unauthorized()"
    "RefundTransferFailure()"
    "InsufficentFees()"
    "FeesTransferFailure()"
)

# Loop through each custom error
for error in "${custom_errors[@]}"; do
    # Use cast to get the signature of the error
    sig=$(cast sig "$error")

    # Extract just the function selector (first 4 bytes of the hash)
    selector=$(echo $sig | cut -c 1-10)

    # Check if this selector matches the error code
    if [[ "$selector" == "0x$error_code" ]]; then
        echo "Match found: $error with signature $selector"
        break
    fi
done

