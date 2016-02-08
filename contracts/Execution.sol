contract ExecutableInterface {
    // Must implement these functions.
    function step(uint currentStep, bytes _state) public returns (bytes result, bool);
    function isFinished() constant returns (bool);
    function getOutputHash() constant returns (bytes32);
    function requestOutput(bytes4 sig) public returns (bool);

    function execute() public;
    function executeN() public returns (uint i);
    function executeN(uint nTimes) public returns (uint iTimes);
}


contract ExecutableBase is ExecutableInterface {
    /*
     *  This is the base class used for on-chain verification of a computation.
     */
    function ExecutableBase(bytes _args) {
        input = _args;
    }

    function isFinished() constant returns (bool) {
        return isFinal;
    }

    // `input` is the initial arguments that will be passed into step-1 of
    // computation.
    bytes public input;

    // `output` is used to store the final return value of the function.
    bytes public output;

    function getOutputHash() constant returns (bytes32) {
        if (!isFinal) return;
        return sha3(output);
    }

    function requestOutput(bytes4 sig) public returns (bool) {
        if (isFinal) {
            return msg.sender.call(sig, output.length, output);
        }
        return false;
    }

    // Stateful variables to track state between steps.
    uint public currentStep;
    bytes public state;
    bool public isFinal;

    function execute() public {
        /*
         * Execute a single step of the computation.
         */
        if (isFinal) throw;

        currentStep += 1;

        if (currentStep == 1) {
            // If this is the first step then the `input` is the initial
            // contract state which is passed into the step function.
            (state, isFinal) = step(currentStep, input);
        }
        else {
            // For all subsequent steps (after the 1st), the output of the
            // previous step is used as the input.
            (state, isFinal) = step(currentStep, state);
        }

        if (isFinal) {
            output = state;
            delete state;
        }
    }

    // These two values serve to ensure that when the transaction gas has been
    // consumed such that another step cannot be executed there is still enough
    // gas remaining to finish execution of the current function context.
    uint constant GAS_RESERVE = 21000;
    uint constant GAS_BUFFER = 21000;

    function executeN() public returns (uint i) {
        // This function is shorthand for `executeN(0)`
        return executeN(0);
    }

    function executeN(uint nTimes) public returns (uint iTimes) {
        /*
         *  Execute the function up to N times.
         *  * N == 0 indicates execution should continue indefinitely until all
         *    gas has been consumed.
         *  * Exits in the case that `isFinal` is true;
         */
        if (isFinal) throw;

        while (!isFinal && (nTimes == 0 || iTimes < nTimes) && msg.gas > GAS_RESERVE + GAS_BUFFER) {
            // This uses .call(..) to isolate any possible out-of-gas exeception.
            if (address(this).call.gas(msg.gas - GAS_RESERVE)(bytes4(sha3("execute()")))) {
                iTimes += 1;
            }
            else {
                break;
            }
        }
        return iTimes;
    }
}
