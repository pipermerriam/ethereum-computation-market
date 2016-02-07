On Chain Computation
====================

The Computation Marketplace is intended for algorithms which are sufficiently
complex that performing them on-chain will be costly.  For many algorithms,
this also means that computation must be split across multiple steps to fit
within the **gas limit** of the EVM.

API Requirements
^^^^^^^^^^^^^^^^

A developer authoring an algorithm for the the computatoin market **must**
conform to the following API requirements.


Execution Contract
~~~~~~~~~~~~~~~~~~

All algorithms must be implented as a contract with the following API.

It **Must** take a ``bytes`` value for any arguments receives as input.  

It **Must** implement the following functions.

isStateless()
"""""""""""""

* ``isStateless() constant returns (bool)`` 
  
Returns whether this computation relies on intermediate state.  If each step
of execution only relies on the output of the previous step then this should
return ``true``.  Otherwise it should return ``false``.


isFinished()
""""""""""""

* ``function isFinished() constant returns (bool)``


    function getOutputHash() constant returns (bytes32);
    function requestOutput(bytes4 sig) public returns (bool);

    function step(uint currentStep, bytes _state) public returns (bytes result, bool);
    function execute() public;
    function executeN(uint nTimes) public returns (uint iTimes);


Factory
~~~~~~~

They must provide the address to a *Factory* contract which exposes 
