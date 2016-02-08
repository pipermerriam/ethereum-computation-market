On Chain Computation
====================

The Computation Marketplace is intended for algorithms which are sufficiently
complex that performing them on-chain will be costly.  For many algorithms,
this also means that computation must be split across multiple steps to fit
within the **gas limit** of the EVM.


Stateless Computations
^^^^^^^^^^^^^^^^^^^^^^

An executable is **stateless** if the implementation does not require
any additional data beyond the output from the previous step.

A fibonacci computation that was stateless would be implemented such that each
step of computation returned the two most recently computed fibonacci numbers.
This would allow each step to operate purely on the return value of the
previous step.

This design allows for computation of the 3rd fibonacci number to be
executed as follows.

* `fib_3rd = fib.step(3, fib.step(2, fib.step(1, "3")))`

Each of these calls could be made using `.call()` allowing all computation to
be done using the on-chain implementation without actually sending any
transactions.

Executable contracts that are **stateless** are superior to **stateful**
implementations in cases where the **stateless** implementation does not
introduce unacceptable complexity.  Stateless implementations allow for
participants in the computation market to compute the requested computation
using the actual on-chain implementation.

The fibonacci example is best done as stateless since the implementation
overhead of returning the latest two fibonacci numbers is small.

Statefull Computations
^^^^^^^^^^^^^^^^^^^^^^
An executable is **stateful** if the implementation requires additional
information beyond the return value of the previous step.  

A fibonacci implementation that was stateful might store each computed number
in contract storage, only returning the latest computed number.  On each step,
this function would need to lookup the computed number from two steps ago in
order to compute the next number.  This reliance on local state is what makes
the contract **stateful**.  It also disallows using `.call()` to compute the
final result since each execution of the `step` function must be done within a
transaction in order to update the local state of the contract.

An algorithm like scrypt could theoretically be done as a stateless contract,
but each step would have to return a very large lookup table due to the
the nature of the scrypt algorithm.  This large input and return value would
reduce the number of actual computations that could be executed in a single
step which would cause a significant increase in the total number of steps
necessary to complete the computation.


Authoring an Algorithm
^^^^^^^^^^^^^^^^^^^^^^

The simplest way to author a new algorithm is to use the abstract solidity
contracts provided by the service.

StatelessExecutable and StatefulExecutable
""""""""""""""""""""""""""""""""""""""""""

* ``contracts/Execution/Execution.sol::StatelessExecutable``
* ``contracts/Execution/Execution.sol::StatelessExecutable``

These abstract contracts can be used to implement **stateless** or **stateful**
algorithms.  They only require implementating the ``step`` function from the
*Execution Contract** api.


FactoryBase
"""""""""""

* ``contracts/Factory.sol::FactoryBase`` 

This abstract contract can be used to implement the *Factory* API for an
*Execution Contract*.  It requires you implement either a ``_build`` function
which returns the address of the newly deployed *Execution Contract*.  This
function implements a default ``build`` function which logs an event with the
address of the newly deployed contract which can be overridden if this behavior
isn't wanted.


Example Stateless Fibonacci Contracts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The following example code implements a **stateless** *Execution Contract* and
*Factory* for computing fibonacci numbers.


.. code-block:: solidity

    import {StatelessExecutable, ExecutableBase} from "contracts/Execution.sol";
    import {FactoryBase} from "contracts/Factory.sol";


    contract Fibonacci is StatelessExecutable {
        function Fibonacci(bytes args) StatelessExecutable(args) {
        }

        function step(uint currentStep, bytes _state) public returns (bytes result, bool) {
            /*
             *  Uses a 64-byte return value to serialize the previous two
             *  computed fibonacci numbers.
             */
            uint i;
            bytes memory fib_n;

            if (currentStep == 1 || currentStep == 2) {
                // special case the first two fibonacci numbers
                fib_n = toBytes(1);
            }
            else {
                // otherwise extract the previous two fibonacci numbers from
                // the previous return value to compute the next fibonacci number.
                var n_1 = _state.extractUint(0, 31);
                var n_2 = _state.extractUint(32, 63);
                fib_n = toBytes(n_1 + n_2);
            }

            if (currentStep > toUInt(input)) {
                // If we have computed the desired fibonacci number just return
                // it as a serialized bytes value.
                result = fib_n;
            }
            else if (currentStep == 1) {
                // Special case the first step to initialize the 64-byte return
                // value.
                result = new bytes(64);
                for (i = 0; i < fib_n.length; i++) {
                    result[32 + i] = fib_n[i];
                }
            }
            else {
                // Write the latest two computed numbers to the 64-byte return
                // value.
                result = new bytes(64);
                for (i = 0; i < 32; i++) {
                    result[i] = _state[i + 32];
                    if (i < fib_n.length) {
                        result[32 + i] = fib_n[i];
                    }
                }
            }

            return (result, (currentStep > toUInt(input)));
        }

        /*
         *  Functions used to serialize and deserialize unsigned integers to
         *  and from bytes arrays.
         */
        function toUInt(bytes v) constant returns (uint result) {
            // Helper function which converts a bytes value to an unsigned integer.
            for (uint i = 0; i < v.length; i++) {
                result += uint(v[i]) * 2 ** (8 * i);
            }
            return result;
        }

        function extractUint(bytes v, uint startIdx, uint endIdx) constant returns (uint result) {
            // Helper function which extracts an unsigned integer from a slice
            // of a bytes array.
            if (startIdx >= endIdx || endIdx >= v.length) throw;
            for (uint i = startIdx; i < endIdx; i++) {
                result += uint(v[i]) * 2 ** (8 * (i - startIdx));
            }
            return result;
        }
    }


    contract FibonacciFactory is FactoryBase {
        function FibonacciFactory() FactoryBase("ipfs://test", "solc 9000", "--fake") {

        function _build(bytes args) internal returns (address) {
            var fibonacci = new Fibonacci(args);
            return address(fibonacci);
        }
    }


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

Return ``true`` if the computation has finished, or ``false`` if computation is
in progress.

getOutputHash()
"""""""""""""""

* ``function getOutputHash() constant returns (bytes32)``

Return the ``sha3()`` of the final return value of the computation.  Return
``0x0`` if the function has not completed computation.


requestOutput(bytes4 sig)
"""""""""""""""""""""""""

* ``function requestOutput(bytes4 sig) public returns (bool)``

This function should send the ``bytes`` return value of the computation to the
``msg.sender`` by calling the function indicated by the provided 4-byte
signature as follows.

.. code-block:: solidity

    function requestOutput(bytes4 sig) public returns (bool) {
        if (isFinal) {
            return msg.sender.call(sig, output.length, output);
        }
        return false;
    }

This allows circumvention of the inability of contracts to receive ``bytes``
values from the return values of external function calls.


step(uint currentStep, bytes _state)
""""""""""""""""""""""""""""""""""""

* ``function step(uint currentStep, bytes _state) public returns (bytes result, bool)``

This function should perform one unit of computation that is sufficiently small
to fit within the EVM **gas limit**.

It will be provided the following arguments.

* **uint currentStep** - The 1-indexed step number for the current computation.
  This increases by one each time the contract executes a unit of computation.
* **bytes _state** - The return value from the previous step, or the ``bytes``
  input value that the contract was initialized with if this is the first step.

This function must return a tuple of ``(bytes, bool)`` where the ``bool`` value
indicates whether computation has completed.


execute()
"""""""""

* ``function execute() public``

A call to this function **must** advance the computation by a single step.  If
the computation has already completed, this function **should** throw an
exception.


executeN(uint nTimes)
"""""""""""""""""""""

* ``function executeN(uint nTimes) public returns (uint iTimes)``

A call to this function **should** advance the computation up to but not
exceeding **nTimes**.  This function **must** interpret ``nTimes == 0`` as
instruction to run as many steps as possible prior to returning.  This function
**must** return the number of steps that were completed.  This function
**should** throw an exeception if computation has already completed when
called.  This function **must** handle the case where execution of **nTimes**
steps would exceed the **gas limit** and still execute successfuly in these
cases.


Factory
~~~~~~~

This contract is used to deploy instances of the *Execution Contract**.

It **must** implement the following API.


sourceURI()
"""""""""""

* ``function sourceURI() returns (string)``

Returns the URI where the source code for this contract can be found.


compilerVersion()
"""""""""""""""""

* ``function compilerVersion() returns (string)``

Returns information about the compiler and version which should be used to
recompile the bytecode of this contract.


compilerFlags()
"""""""""""""""

* ``function compilerFlags() returns (string)``

Returns any configuration arguments that should be used to recompile the
bytecode of this contract.


build(bytes args)
"""""""""""""""""

* ``function build(bytes args) public returns (address addr)``

A call to this function should deploy a new instance of the *Execution
Contract* initialized with the provided ``bytes args`` value.  This function
**must** return the address of a contract which conforms to the *Execution
Contract* API and which can be used to compute the result of the computation
given the provided ``bytes args`` input value.


isStateless()
"""""""""""""

* ``isStateless() constant returns (bool)`` 
  
Returns whether this factory's *Execution Contract* is **stateless** or
**stateful**.  If each step of execution only relies on the output of the
previous step then this should return ``true``.  Otherwise it should return
``false``.


totalGas()
""""""""""

* ``function totalGas(bytes args) constant returns(int)``

Returns the total gas estimate in wei that would be required to compute the
computation for the given input.
