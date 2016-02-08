Events
======

The computation market contracts emit the following events.

Broker Contract Events
-------------

Created
^^^^^^^

* ``event Created(uint id, bytes32 argsHash)``

Logged when a new computation request is created.

.. glossary::

    uint id
        The id of the request
    bytes32 argsHash
        The sha3 of the computation arguments.


Cancelled
^^^^^^^^^

* ``event Cancelled(uint id)``

Logged when a computation request is cancelled.

.. glossary::

    uint id
        The id of the request


AnswerSubmitted
^^^^^^^^^^^^^^^

* ``event AnswerSubmitted(uint id, bytes32 resultHash, bool isChallenge)``

Logged when either the initial answer or an answer challenge is submitted.

.. glossary::

    uint id
        The id of the request
    bytes32 resultHash
        The sha3 of the submitted answer
    bool isChallenge
        Whether the submitted answer was the initial answer or an answer
        challenge.


Execution
^^^^^^^^^

* ``event Execution(uint id, uint nTimes, bool isFinished)``

Logged when the on chain execution contract has advanced at least one step in
execution.

.. glossary::

    uint id
        The id of the request
    uint nTimes
        The number of execution steps that were completed successfully.
    bool isFinished
        Boolean indicating if on-chain computation has completed.


GasReimbursement
^^^^^^^^^^^^^^^^

* ``event GasReimbursement(uint id, address to, uint value)``

Logged when a gas reimbursement is sent.

.. glossary::

    uint id
        The id of the request
    address to
        The address that the reimbursement was sent to.
    uint value
        The amount in wei that was sent.


Payment
^^^^^^^

* ``event Payment(uint id, address to, uint value)``

Logged when the payment for a computation is sent.

.. glossary::

    uint id
        The id of the request
    address to
        The address that was paid.
    uint value
        The amount in wei that was sent.


DepositReturned
^^^^^^^^^^^^^^^

* ``event DepositReturned(uint id, address to, uint value)``

Logged when a deposit is returned to either the initial answer submitter or the
challenger.

.. glossary::

    uint id
        The id of the request
    address to
        The address that was returned.
    uint value
        The amount in wei that was sent.


Factory Contract
----------------

A *Factory* contract *should* emit the following events.

.. note::

    Each algorithm author is in full control of how they construct their
    Factory contract.  These events are not part of the required API so it may be
    left out for some markets.


Constructed
^^^^^^^^^^^

* ``event Constructed(address addr, bytes32 argsHash)``

Logged when a new *Execution Contract* is deployed.

.. glossary::

    address addr
        The address of the newly created contract
    bytes32 argsHash
        The sha3 of the constructor arguments that were passed to the the
        contract.


Execution Contract
------------------

The *Execution Contract* API does not define any event.
