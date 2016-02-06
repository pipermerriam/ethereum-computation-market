What is it?
===========

This is a service on the Ethereum blockchain that facilitates execution of
computations that would be too costly to perform within the Ethereum Virtual
Machine (EVM).

Running code on the EVM has a cost which makes it costly to perform
large computations.  Each execution of code within the EVM must be paid for
using an abstraction referred to as **gas**.  Complex computations could get
expensive very quickly as they would require a large quantity of gas to be
executed.

The Computation Marketplace allows for someone to pay someone to execute an
algorithm outside of the network and report the result back to them.  Each
algorithm will have an on-chain implementation which can be used to verify
whether the submitted result is correct.  In the event of a dispute over what
the correct result is, the on chain version of the computation is executed to
determine the correct answer.
