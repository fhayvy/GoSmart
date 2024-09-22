# Smart Contract Insurance - Clarity Smart Contract

This repository contains a Clarity smart contract implementing a basic insurance system for other smart contracts on the Stacks blockchain.

## Overview

The Smart Contract Insurance system allows other contracts (or users) to purchase insurance, file claims, and receive payouts if their claims are approved. The contract manages an insurance pool and keeps track of insured contracts and pending claims.

## Features

- Purchase insurance
- File claims
- Approve and pay out claims
- Reject claims
- Check and expire claims
- Check insurance pool balance
- Verify if a contract is insured
- Get insured amount for a contract
- Get claim status for a contract
- Event logging for key actions

## Contract Functions

### Public Functions

1. `purchase-insurance`: Allow a contract to purchase insurance by sending STX to the insurance pool.
2. `file-claim`: File a claim for an insured contract.
3. `approve-claim`: Approve and pay out a claim (restricted to contract owner).
4. `reject-claim`: Reject a filed claim (restricted to contract owner).
5. `check-and-expire-claim`: Check and expire a claim if it has passed the expiration period.
6. `change-contract-owner`: Change the owner of the contract (restricted to current owner).

### Read-Only Functions

1. `get-pool-balance`: Get the current balance of the insurance pool.
2. `is-insured`: Check if a contract is insured.
3. `get-insured-amount`: Get the insured amount for a specific contract.
4. `get-claim-status`: Get the claim status for a specific contract and claim amount.

## Event Logging

The contract implements event logging for key actions to enhance transparency and auditability. The following events are logged:

1. Insurance Purchase: Logs when a contract purchases insurance.
2. Claim Filing: Logs when an insured contract files a claim.
3. Claim Approval: Logs when a claim is approved and paid out.
4. Claim Rejection: Logs when a claim is rejected.
5. Claim Expiration: Logs when a claim is expired.
6. Contract Owner Change: Logs when the contract owner is changed.

These events can be monitored on the Stacks blockchain for auditing purposes.

## Usage

To use this smart contract, deploy it to the Stacks blockchain and interact with it using the provided functions. Make sure to have the necessary STX balance when purchasing insurance or approving claims.

## Security Considerations

- This is a basic implementation and should not be used in production without thorough auditing and testing.
- The contract includes event logging for improved transparency, but additional security measures may be necessary.
- The `approve-claim` and `reject-claim` functions are restricted to the contract owner to prevent unauthorized actions.
- The contract now includes additional checks to ensure claim amounts do not exceed insured amounts.
- A claim expiration mechanism is implemented to automatically expire claims after a certain period.
- Consider implementing additional checks and balances, such as claim verification mechanisms and tiered insurance plans.

## Recent Improvements

1. Added a new error constant `ERR_CLAIM_EXCEEDS_INSURED` to handle cases where the claim amount exceeds the insured amount.
2. Improved the `approve-claim` function to include additional checks:
   - Verifies that the claim amount doesn't exceed the insured amount.
   - Ensures that the claim hasn't expired before processing.
3. Implemented a `check-and-expire-claim` function to automatically expire claims after a set period.
4. Enhanced error handling and input validation throughout the contract.

## Author 
Favour Chiamaka Eze
