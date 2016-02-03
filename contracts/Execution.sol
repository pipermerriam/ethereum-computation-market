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
    bytes public input;
    bytes public output;

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
            (state, isFinal) = step(currentStep, input);
        }
        else {
            (state, isFinal) = step(currentStep, state);
        }

        if (isFinal) {
            output = state;
            delete state;
        }
    }

    uint constant GAS_RESERVE = 21000;
    uint constant GAS_BUFFER = 21000;

    function executeN() public returns (uint i) {
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
