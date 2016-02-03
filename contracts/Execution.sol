contract ExecutableInterface {
    /*
     *  Constant getters
     */
    function isFinal() constant returns(bool);
    function getState() constant returns (uint, bytes, bytes, bool);

    // Must implement this function.
    function step(uint step, bytes args) constant returns (bytes result, bool isFinal);

    function execute() public;
}


contract Executable is ExecutableInterface {
    /*
     *  This is the base class used for on-chain verification of a computation.
     */
    bytes public input;
    bytes public output;

    struct State {
        uint step;
        bytes args;
        bytes result;
        bool isFinal;
    }

    State[] stateHistory;

    function step(bytes args, State storage next) internal {
        // record the in-bytes for this step
        next.args = args;

        (next.result, next.isFinal) = step(next.step, args);

        if (next.isFinal) {
            output = next.result;
        }
    }

    function isFinal() constant returns(bool) {
        if (stateHistory.length == 0) return false;
        return stateHistory[stateHistory.length - 1].isFinal;
    }

    function getState() constant returns (uint, bytes, bytes, bool) {
        if (stateHistory.length == 0) throw;
        return getState(stateHistory.length - 1);
    }

    function getState(uint step) constant returns (uint, bytes, bytes, bool) {
        var state = stateHistory[step];
        return (state.step, state.args, state.result, state.isFinal);
    }

    function execute() public {
        /*
         * Execute a single step of the computation.
         */
        if (isFinal()) throw;
        var next = State({
            step: stateHistory.length,
            args: "",
            result: "",
            isFinal: false
        });
        stateHistory.push(next);

        if (next.step == 0) {
            step(input, stateHistory[next.step]);
        }
        else {
            step(stateHistory[next.step - 1].result, stateHistory[next.step]);
        }
    }
}
