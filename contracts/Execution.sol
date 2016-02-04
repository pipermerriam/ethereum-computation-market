contract ExecutableInterface {
    /*
     *  Constant getters
     */
    // Must implement this function.
    function step(uint step, bytes state) constant returns (bytes result, bool isFinal);

    function execute() public;
    function executeN() public returns (uint i);
    function executeN(uint n) public returns (uint i);
}


contract Executable is ExecutableInterface {
    /*
     *  This is the base class used for on-chain verification of a computation.
     */

    // `input` is the initial arguments that will be passed into step-1 of
    // computation.
    bytes public input;

    // `output` is used to store the final return value of the function.
    bytes public output;

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

    function executeN(uint n) public returns (uint i) {
        /*
         *  Execute the function up to N times.
         *  * N == 0 indicates execution should continue indefinitely until all
         *    gas has been consumed.
         *  * Exits in the case that `isFinal` is true;
         */
        if (isFinal) throw;

        while (!isFinal && (n == 0 || i < n) && msg.gas > GAS_RESERVE + GAS_BUFFER) {
            // This uses .call(..) to isolate any possible out-of-gas exeception.
            if (address(this).call.gas(msg.gas - GAS_RESERVE)(bytes4(sha3("execute()")))) {
                i += 1;
            }
            else {
                break;
            }
        }
        return i;
    }
}
