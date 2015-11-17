# Ethereum Computation Marketplace

Some computations are too expensive to justify doing them on the blockchain,
yet may be necessary for certain contracts to operate.  The Ethereum
Computation Market aims to solve this problem.

The general process works as follows.  We'll use computation of the fibonacci
sequence as an example.

1. First, we implement the algorithm as a contract.
2. A contract wanting the Nth member of the sequence would submit their
   computation request to the service.
3. The request is picked up by an off-network entity, computed, and the result
   submitted to the service along with a deposit sufficient to cover the on-chain
   computation.
4. A group of verifiers monitors the computation responses, checking them
   against their computed version of the correct answer.  Any verifier may
   challenge the answer by providing an equal deposit.
5. If not challenged, the answer is finalized and can be trusted after some
   waiting period.
6. If challenged, the computation is executed on-chain, and whichever party was
   wrong (submitter or verifier) pays the gas costs for the computation.  The
   other part is refunded their deposit plus a payment for their service.

## Status

This is a fully functional proof of concept for this service.  It still needs
some work to be a robust enough solution, as well as thorough documentation on
the API that the on-chain computation contracts must implement.

# Notes

* A Computation Is:
    * A verifier contract is a contract that implements the full algorithm.
    * The ABI signature of the computation function.
    * Documentation link (IPFS/URI)
      information is useful.
    * Maximum Stack Depth.
    * Minimum computation gas.
* A Request Is:
    * Willing to pay up to X.
        * X is likely based on the expected gas usage of the algorithm
    * Input bytes
    * (Potentially) bidding on computation.
* Request a computation.
* Submission of 'candidate' result. (includes deposit)
* Waiting period for objection (alarm integration? auto-return deposit)
* Object to result (provide real result)
    * Verified via verifier contract.


## Things that need to be tested.

* Request comes with:
    * Payment ether
    * Fee ether
* Off Chain Result comes with:
    * Computation ether.
    * Challenge payment ether.
* Challenge
    * Enough to pay for computation.
* Finalize
    * Only after N blocks without challenge.
    * Releases bond
    * Sends payments to computer and finalizer.
