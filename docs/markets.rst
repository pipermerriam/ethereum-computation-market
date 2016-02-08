Markets
=======

The Marketplace is composed of many individual *markets* which each offer
computation of a specific algorithm.


Components
----------

Each algorithm is comprised of three distinct contracts.

* Broker
* Factory
* Execution Contract


Broker
^^^^^^

The *Broker* contract coordinates the requests and fulfillments of computations.


Factory
^^^^^^^

The *Factory* contract handles deployment of the *Execution* contracts in the
event that an answer is disputed and must be computed on-chain.  The Factory
packages the *Execution* contract as well as providing meta-data such as
compiler version which would be needed to recompile and verify the bytecode.


Execution
^^^^^^^^^

The *Execution* contract is the actual implementation of the algorithm.  It can
carry out one full on-chain execution of the computation.


Risks
-----

It is not safe to blindly participate as either the requester or fulfiller in a
market.  The computation marketplace can provide a trustless wrapper around
each algorithm, but it cannot guarantee the correctness or fairness of the
underlying algorithm.  Since algorithms are implemented as smart contracts they
are capable of anything that a smart contract can do.
