Computation Requests
====================

A *Computation Request* is an offer to pay someone to compute a given
marketplace computation off chain in exchange for a payment.


Creating a Request
------------------

``function requestExecution(bytes args, uint softResolutionBlocks) public returns (uint)``

The ``requestExecution`` function can be used to create a request for
computation.  This function takes two arguments as well as an ether value which
specifies the payment amount being offered for this computation.

* ``bytes args`` is the *serialized* inputs to the function.
* ``uint softResolutionBlocks`` is the number of blocks after an initial answer
  has been submitted before the answer should be assumed correct if no
  challenge has been received.  Once this limit has passed the request can be
  finalized.

Any *ether* sent along with this function is set as the payment amount that
will be sent in exchange for fulfilling the request.

This function returns an unsigned integer which is the *id* of the created
request.  This *id* is necessary for all future actions on the request.


Request Details
---------------

The details of a request can be queried with the following three functions::

    function getRequest(uint id) constant returns (bytes32 argsHash,
                                                   bytes32 resultHash,
                                                   address requester,
                                                   address executable,
                                                   uint creationBlock,
                                                   Status status,
                                                   uint payment,
                                                   uint softResolutionBlocks,
                                                   uint gasReimbursements,
                                                   uint requiredDeposit);
    function getRequestArgs(uint id) constant returns (bytes result);
    function getRequestResult(uint id) constant returns (bytes result);


The primary function ``getRequest`` returns the following values.

* ``bytes32 argsHash``:  The *sha3* of the ``args`` input value for this
  request.
* ``bytes32 resultHash``:  The *sha3* of the ``result`` of this computation.
  This will return ``0x0`` if the request has not been finalized.
* ``address requester``: The address that requested the computation.
* ``address executable``: The address of the executable contract that was
  deployed to settle a challenged answer.  This will be ``0x0`` if no challenge
  has been made.
* ``uint creationBlock``:: The block number on which this request was created.
* ``uint status``:: Unsigned integer related to the ``Status`` enum.  See Request
  Status for more details.
* ``uint payment``:: The amount in wei that this request will pay in exchange
  for fullfillment of the computation.
* ``softResolutionBlocks``:: The number of blocks after answer submission
  before the answer deposit may be reclaimed if no challenge has been
  submitted.
* ``gasReimbursements``:: Amount in wei that has been paid out so far in gas
  reimbursments during dispute resolution.
* ``requiredDeposit``:: Amount in wei that must be provided when submitting an
  answer to this request as well as challenging that submitted answer.


Request Status
--------------

Computation requests use an **Enum** to track their status.  The possible
values are.
    
* **0**: Pending: Created but has no submitted answers.
* **1**: WaitingForResolution: Has exactly one answer.  This answer has not
  been verified or accepted, nor has it been submitted long enough to
  allow the submitter to reclaim their deposit.
* **2**: NeedsResolution: Has a challeng answer.  Neither of the answers have
  and resolution has not begun.
* **3**: Resolving: Resolution has been initiated and is in-progress.
* **4**: SoftResolution: This request has a single answer which has not been
  challenged and was submitted long enough ago that the submitter has
  been allowed to reclaim their deposit.
* **5**: FirmResolution: This request has an answer which was verified via the
  on-chain implementation of the computation.
* **6**: Finalized: This request has a result.  Deposits may now be returned
  and payment issued.
* **7**: Cancelled: The request has been cancelled.

The current status of a request can be gotten by looking at the unsigned
integer value at index **7** returned from ``getRequest``.
    

Cancelling
----------

* ``function cancelRequest(uint id) public``

A computation request can be cancelled as long as no answers have been
submitted.  Cancellation is done with the ``cancelRequest`` function which
takes the *id* of the request to be cancelled as its sole argument.

Only the requester of the computation may cancel a request.


Submitting an Answer
--------------------

* ``function answerRequest(uint id, bytes result) public``

Submition of an answer to a computation is done with the ``answerRequest``
function.  It takes the *id* of the request being answered as well as the
``bytes`` serialized answer to the computation.

Answer Deposit
^^^^^^^^^^^^^^

Answer submission requires a deposit in ether.  This deposit is held until the
request has reached either a soft or hard resolution.  The required deposit
amount can be gotten from the unsigned integer value at index 9 of the return
value of ``getRequest``.


Soft Resolution
---------------

* ``function softResolveAnswer(uint id) public``

Soft resolution occurs when an answer is accepted without being challenged.  If
the address which requested the computation chooses, they can call the
``softResolveAnswer`` anytime after submission to accept the answer and
transition it into the **SoftResolution** status.

Otherwise, after the number of blocks specified by **softResolutionBlocks**
have passed since the submission of the answer, anyone may call this function.


Finalization
------------

* ``function finalize(uint id) public returns (bytes32)``

Once a request is in either the **SoftResolution** or **FirmResolution** status
it can be finalized via the ``finalize`` function.  This function sets the
final result of the computation, pays the correct parties for their
computation, and returns the *sha3* of the result as a return value.


Reclaiming Deposits
-------------------

* ``function reclaimDeposit(uint id) public``

Once a request has been finalized, the deposits of the answer submitter and
challenger can be reclaimed.  If the submitted answer was found to be incorrect
during on-chain computation the deposit will have had the gas costs of that
computation deductd from it.
