contract ComputationBase {
    struct Answer {
        uint id;
        address submitter;
        bytes result;
        uint createdAt;
    }

    struct Request {
        uint id;
        bytes args;
        uint createdAt;
        uint finalAnswer;
        Answer[] answers;
        mapping (bytes32 => bool) seen;
    }

    // Request a computation to be done.
    function requestExecution(bytes args) public returns (uint);

    // Submit an answer to a requested computation.
    function answerRequest(uint id, bytes result) public returns (uint);

    // Challenge an answer
    function challengeAnswer(uint requestId, uint answerIdx, bytes result) public;

    /*
     * Resolve a request
     *
     * Finalizes an answered computation.
     */
    function resolveRequest(uint id) public returns (uint);
    
    // Deploy the execution contract.
    function deployExecution(bytes args) public returns (address);
}


contract Computation is ComputationBase {
    uint _idx;

    mapping (uint => Request) requests;

    function requestExecution(bytes args) public returns(uint) {
        _idx += 1;

        var request = requests[_idx];

        request.id = _idx;
        request.args = args;
        request.createdAt = block.number;


        return _idx;
    }

    function answerRequest(uint id, bytes result) public returns (uint) {
        var request = requests[id];

        // invalid request id.
        if (request.id == 0) throw;

        var resultHash = sha3(result);

        // this answer has already been submitted.
        if (request.seen[resultHash]) throw;

        var answer = Answer({
            id: request.answers.length,
            submitter: msg.sender,
            result: result,
            createdAt: now
        });
        request.seen[resultHash] = true;

        return answer.id;
    }
}
