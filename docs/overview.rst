Overview
========

The **Computation Market** facilitates the execution of expensive computations
off-chain in a manner that is both trustless and verifiable.


How it works
============

The marketplace can only fulfill computation requests for algorithms that have
been implemented within the EVM.  A user who wishes to have one of these
algorithms computed for them would submit the desired input for that algorithm
as a ``bytes`` value along with a payment for whoever fulfills the request.

Answering to the request involves both submitting the result of the computation
as well as a deposit.  This deposit is determined by the cost of executing the
computation on chain and thus will vary for each algorithm.  The deposit must
be sufficient to pay the full gas costs for on-chain execution.

After the answer is received the request has a wait period during which someone
may challenge the answer.  The challenge must also submit what they believe to
be the correct computation result along with an equal deposit.

If no challenge is received within a certain number of blocks, the the answer
can be finalized at which point the submitter may reclaim their deposited funds
along with the payment for their computation.

In the event of a challenge, the computation is carried out on-chain.  The
result of the on-chain computation is used to check the submitted answers.  If
either answer is correct, that submitter is paid the payment for their
computation and returned their full deposit.  The submitter which submitted the
wrong answer may claim the remainder of their deposit that is left after having
the gas costs for the on-chain computation deducted.

.. note::

    In the event that neither the original answer submitter and the challenger
    submitted the correct answer, the gas costs for on-chain computation are
    split evenly between them and the payment value is sent back to the user
    who requested the computation.
