# Mechanisms

* A Computation Is:
    * A verifier contract is a contract that implements the full algorithm.
    * The ABI signature of the computation function.
    * Documentation link (IPFS/URI)
    * (Potentially) needs to record gas usage of the computation.  This
      information is useful.
    * (Potentially) flag for constant and deterministic (can re-use results)
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

