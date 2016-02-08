Challenging Answers
===================

The core mechanism that allows the computation marketplace to operate is the
ability to perform the computation on-chain in the event of a dispute.  In the
event that a participant in the computation side of the marketplace sees an
answer submitted to a request which does not match their own computations, they
may *challenge* the answer.

This initiates a 3-step process which will execute the computation within the
EVM to verify which submitted answer is correct.  The gas costs for this
computation are paid for from the deposit of the incorrect submitter.


Step 1: Challenge
-----------------

* ``function challengeAnswer(uint id, bytes result) public``

Anytime after an answer has been submitted and the request is in the
**WaitingForResolution** the answer may be challenged with the
``challengeAnswer``.  The arguments for challenging and answer are the same as
the ``answerRequest`` function.


Challenge Deposit
^^^^^^^^^^^^^^^^^

Challenging an answer requires the same deposit amount as the initial answer
submission.  This minimum value is returned at the 9th index of the return
value of ``getRequest``.


Retrieve Challenge Answer
^^^^^^^^^^^^^^^^^^^^^^^^^

The data related to the challenge answer can be retrieved with the following
functions::

    function getChallengeAnswer(uint id) constant returns (bytes32 resultHash,
                                                           address submitter,
                                                           uint creationBlock,
                                                           bool isVerified,
                                                           uint depositAmount);
    function getChallengeAnswerResult(uint id) constant returns (bytes);

These two functions follow the same API and return values as the
``getInitialAnswer`` and ``getInitialAnswerResult`` functions.


Step 2: Initialize Dispute
--------------------------

* ``function initializeDispute(uint id) public returns (address)```

Once an answer has been challenged, it needs to have the dispute resolution
initialized.  This is done by calling the ``initializeDispute``.  This function
may be called by anyone once a challenge has been submitted.  The broker
contract will use it's *factory* to deploy a new *executable* contract
initialized with the inputs for this request.

The gas costs for calling this function are fully reimbursed during execution.


Step 3: Computation & Resolution
--------------------------------

* ``function executeExecutable(uint id, uint nTimes) public returns (uint i, bool isFinished)``

Once the dispute has been initialized, the ``executeExecutable`` function must
be called until the the computation has been completed.  Once computation
completes the function will be set to the **FirmResolution** status.

The gas costs for calling this function are fully reimbursed during execution.


Finalization
------------

Once a request is in the **FirmResolution** status it can be finalized the same
as if it were soft resolved.  In the **FirmResolution** case, the result of the
on-chain computation is set as the final result of the requested computation.

* If one of the submitted answers was correct, they may then reclaim their full
  deposit and are sent the payment value in wei.
* If both of the submitted answers were wrong, the submitters split the gas
  costs evenly.  In this case, the payment value is returned to the address
  that requested the computation.
* Either submitter who's answer was incorrect can reclaim the remainder of
  their deposit that was not used for on-chain gas costs.
