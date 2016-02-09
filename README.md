# Ethereum Computation Marketplace

[![Gitter](https://badges.gitter.im/pipermerriam/ethereum-computation-market.svg)](https://gitter.im/pipermerriam/ethereum-computation-market?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Documentation Status](https://readthedocs.org/projects/ethereum-computation-market/badge/?version=latest)](https://readthedocs.org/projects/ethereum-computation-market/?badge=latest)

A semi-trustless on chain marketplace for purchasing the execution and result
of expensive computation.

## Status

2015-11-16 - Fully functional proof of concept for this service.  It still needs
some work to be a robust enough solution, as well as thorough documentation on
the API that the on-chain computation contracts must implement.

2016-02-04 - In development.

## Initial Idea

Credit for this idea goes to [Tal Serphos](https://twitter.com/TalSerphos)

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


## Components

### Broker

This is the primary contract which manages computation requests and fulfillment
of a given computation.


### Factory

A Factory is a contract which exposes a function which will deploy an new
instance of a certain type of `Executable` contract.

### Executable

A contract which implements an algorithm such that it can be computed on chain.
This likely involves a mechanism for splitting the computation across many
steps.  In order to be sufficiently abstract, these contracts operate
exclusively on the `bytes` type, both as the input, as well as storage for
intermediate steps during the computation.  This provides a high level of
flexibility in exchange for requiring computations to implement their own
serialization/deserialization logic.

The required API for an executable is as follows:

* An executable contract takes a `bytes` value in it's constructor which
  represents the input parameters to the computation.
* The executable must implement a 
  `step(uint currentStep, bytes _state) returns (bytes _nextState, bool _isFinal)`
  function.  `currentStep` is the 1-indexed step number for the current state
  of computation.  `_state` is the return value from the previous step.  If
  this is the first step (step #1) then the `_state` value will be the `bytes`
  value that was passed in as the constructor.
* The `step(..)` function must return a 2-tuple of `(bytes, bool)`.  The
  `bytes` value is the updated `_state` that will be passed into the next step.
  The `bool` value indicates whether the computation has completed.


### Stateful vs Stateless executables


#### Stateless

An executable is **stateless** if the implementation does not require
any additional data beyond the output from the previous step.

A fibonacci implementation that was stateless would return a bytes value that
represented the previous two computed fibonacci numbers at each step.  This
would allow for computation of the 3rd fibonacci number to be executed as
follows.

* `f_3 = fib.step(3, fib.step(2, fib.step(1, "3")))`

Each of these calls could be made using `.call()` requiring all computation to
be done using the on-chain implementation without actually sending any
transactions.

Executable contracts that are **stateless** are vastly superior to **stateful**
implementations in cases where the **stateless** implementation does not
introduce unacceptable complexity.  The reason for this is that it allows for
participants in the computation market to compute the requested computation
using the actual on-chain implementation.

The fibonacci example is best done as stateless since the implementation
overhead is small.

An algorithm like scrypt could theoretically be done as a stateless contract,
but each step would have to return a very large lookup table due to the
memory-hardness feature of scrypt.  This large input and return value would
reduce the number of actual computations that could be executed in a single
step which would cause a significant increase in the total number of steps
necessary to complete the computation.


#### Statefull

An executable is **stateful** if the implementation requires additional
information beyond the return value of the previous step.  

A fibonacci implementation that was stateful might store each computed number
in contract storage, only returning the latest computed number.  On each step,
this function would need to lookup the computed number from two steps ago in
order to compute the next number.  This reliance on local state is what makes
the contract **stateful**.  It also disallows using `.call()` to compute the
final result since each execution of the `step` function must be done within a
transaction in order to update the local state of the contract.
