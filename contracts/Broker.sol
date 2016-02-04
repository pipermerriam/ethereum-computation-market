import {FactoryInterface} from "contracts/Factory.sol";


contract BrokerInterface {
    struct Answer {
        uint id;
        address submitter;
        bytes result;
        uint createdAt;
    }

    struct Request {
        uint id;
        address requester;
        bytes args;
        address executable;
        uint createdAt;
        Answer[] answers;
        mapping (bytes32 => bool) seen;
    }

    /*
     *  Constant getters
     */
    function getRequest(uint id) constant returns (bytes, address, address, uint, uint);
    function getAnswer(uint requestId, uint idx) constant returns (address, bytes, uint);

    /*
     *  Events
     */
    event Created(uint id, bytes32 argsHash);

    // Request a computation to be done.
    function requestExecution(bytes args) public returns (uint);

    // Submit an answer to a requested computation.
    function answerRequest(uint id, bytes result) public returns (uint);

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

    function getRequest(uint id) constant returns (bytes, address, address, uint, uint) {
        var request = requests[id];

        // invalid id
        if (request.id == 0) throw;

        return (request.args, request.requester, request.executable, request.createdAt, request.answers.length);
    }

    function getAnswer(uint requestId, uint idx) constant returns (address, bytes, uint) {
        var request = requests[requestId];

        // invalid id
        if (request.id == 0) throw;

        // invalid idx
        if (idx >= request.answers.length) throw;

        var answer = request.answers[idx];

        return (answer.submitter, answer.result, answer.createdAt);
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
        var request = requests[id];

        // invalid request id.
        if (request.id == 0) throw;

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
        request.seen[resultHash] = true;

        // TODO: if this is not the first answer then it must come with a
        // larger deposit than the previous answer.

        return answer.id;
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
