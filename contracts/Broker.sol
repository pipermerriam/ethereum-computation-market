import {FactoryInterface} from "contracts/Factory.sol";


contract BrokerInterface {
    struct Answer {
        uint id;
        address submitter;
        bytes result;
        uint createdAt;
    }

    /*
     *  Status Enum
     *  - Pending: Created but has no submitted answers.
     *  - WaitingForResolution: Has exactly one answer.  This answer has not
     *    been verified or accepted, nor has it been submitted long enough to
     *    allow the submitter to reclaim their deposit.
     *  - NeedsResolution: Has more than one answer.  None of the 
     *  - 
     */
    enum Status {
        Pending,
        WaitingForResolution,
        NeedsResolution,
        Resolving,
        SoftResolution,
        FirmResolution
    }

    struct Request {
        uint id;
        address requester;
        bytes args;
        address executable;
        uint createdAt;
        Status status;
        Answer[] answers;
        mapping (bytes32 => bool) seen;
    }

    /*
     *  Constant getters
     */
    function getRequest(uint id) constant returns (bytes32, address, address, uint, uint);
    function getRequestArgs(uint id) constant returns (bytes);
    function getAnswer(uint id, uint idx) constant returns (address, bytes32, uint);
    function getAnswerResult(uint id, uint idx) constant returns (bytes);

    /*
     *  Events
     */
    event Created(uint id, bytes32 argsHash);
    event Answered(uint id, uint idx, bytes32 resultHash);

    // Request a computation to be done.
    function requestExecution(bytes args) public returns (uint);

    // Submit an answer to a requested computation.
    function answerRequest(uint id, bytes result) public returns (uint);

    // Submitter explicitely accepts and answer
    function acceptAnswer(uint id, uint idx) public;

    /*
     * Resolve a request
     *
     * Finalizes an answered computation.
     */
    function resolveRequest(uint id) public returns (uint);
    
    // Deploy the execution contract.
    function deployExecution(bytes args) public returns (address);
}


contract Broker is BrokerInterface {
    address public factory;

    function Broker(address _factory) {
        factory = _factory;
    }

    uint _idx;

    mapping (uint => Request) requests;

    /*
     *  Internal getters
     */
    function _getRequest(uint id) internal returns (Request) {
        var request = requests[id];

        // invalid id
        if (request.id == 0) throw;

        return request;
    }

    function _getRequestAnswerPair(uint id, uint idx) internal returns (Request, Answer) {
        var request = _getRequest(id);

        // invalid idx
        if (idx >= request.answers.length) throw;

        var answer = request.answers[idx];

        return (request, answer);
    }

    function _getAnswer(uint id, uint idx) internal returns (Answer) {
        var (request, answer) = _getRequestAnswerPair(id, idx);

        return answer;
    }

    /*
     *  Public getters
     */
    function getRequest(uint id) constant returns (bytes32, address, address, uint, uint) {
        var request = _getRequest(id);

        return (sha3(request.args), request.requester, request.executable, request.createdAt, request.answers.length);
    }

    function getRequestArgs(uint id) constant returns (bytes) {
        var request = _getRequest(id);

        return request.args;
    }

    function getAnswer(uint id, uint idx) constant returns (address, bytes32, uint) {
        var answer = _getAnswer(id, idx);

        return (answer.submitter, sha3(answer.result), answer.createdAt);
    }

    function getAnswerResult(uint id, uint idx) constant returns (bytes) {
        var answer = _getAnswer(id, idx);

        return answer.result;
    }

    function requestExecution(bytes args) public returns (uint) {
        _idx += 1;

        var request = requests[_idx];
        request.id = _idx;
        request.requester = msg.sender;
        request.args = args;
        request.createdAt = now;

        Created(_idx, sha3(args));

        return _idx;
    }

    function answerRequest(uint id, bytes result) public returns (uint) {
        var request = requests[_getRequest(id).id];

        var resultHash = sha3(result);

        // this answer has already been submitted.
        if (request.seen[resultHash]) throw;

        // TODO: require deposit big enough for a full computation (from
        // factory contract)

        var answer = Answer({
            id: request.answers.length,
            submitter: msg.sender,
            result: result,
            createdAt: now
        });
        request.answers.push(answer);

        // Register this result hash as being seen.
        request.seen[resultHash] = true;

        // Log that a new answer was submitted.
        Answered(id, answer.id, resultHash);

        // TODO: if this is not the first answer then it must come with a
        // larger deposit than the previous answer.

        return answer.id;
    }

    function acceptAnswer(uint id, uint idx) public {
        var (request, answer) = _getRequestAnswerPair(id, idx);

        // TODO: how does this work?
    }

    /*
     * To resolve a request
     */
    function resolveRequest(uint id) public returns (uint) {
    }
    // TODO
    
    // Deploy the execution contract.
    function deployExecution(bytes args) public returns (address) {
        return FactoryInterface(factory).build(args);
    }
}
