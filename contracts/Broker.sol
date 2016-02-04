import {FactoryInterface} from "contracts/Factory.sol";


contract BrokerInterface {
    struct Answer {
        address submitter;
        bytes result;
        bytes32 resultHash;
        uint creationBlock;
        bool isVerified;
    }

    /*
     *  Status Enum
     *  - Pending: Created but has no submitted answers.
     *  - WaitingForResolution: Has exactly one answer.  This answer has not
     *    been verified or accepted, nor has it been submitted long enough to
     *    allow the submitter to reclaim their deposit.
     *  - NeedsResolution: Has a challeng answer.  Neither of the answers have
     *    and resolution has not begun.
     *  - Resolving: Resolution has been initiated and is in-progress.
     *  - SoftResolution: This request has a single answer which has not been
     *    challenged and was submitted long enough ago that the submitter has
     *    been allowed to reclaim their deposit.
     *  - FirmResolution: This request has an answer which was verified via the
     *    on-chain implementation of the computation.
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
        bytes32 argsHash;
        bytes result;
        bytes32 resultHash;
        address executable;
        uint creationBlock;
        Status status;
        Answer initialAnswer;
        Answer challengeAnswer;
    }

    /*
     *  Constant getters
     */
    function getRequest(uint id) constant returns (bytes32 argsHash,
                                                   bytes32 resultHash,
                                                   address requester,
                                                   address executable,
                                                   uint creationBlock,
                                                   Status status);
    function getRequestArgs(uint id) constant returns (bytes result);
    function getInitialAnswer(uint id) constant returns (bytes32 resultHash,
                                                                   address submitter,
                                                                   uint creationBlock);

    function getInitialAnswerResult(uint id) constant returns (bytes);
    function getChallengeAnswer(uint id) constant returns (bytes32 resultHash,
                                                                     address submitter,
                                                                     uint creationBlock);
    function getChallengeAnswerResult(uint id) constant returns (bytes);


    /*
     *  Events
     */
    event Created(uint id, bytes32 argsHash);
    event AnswerSubmitted(uint id, bytes32 resultHash);


    /*
     *  Public API
     */
    // Request a computation to be done.
    function requestExecution(bytes args) public returns (uint);

    // Submit an answer to a requested computation.
    function answerRequest(uint id, bytes result) public;

    // Challenge the answer to a question.
    function challengeAnswer(uint id, bytes result) public;

    // Deploy the execution contract.
    function deployExecutable(uint id) public returns (address);
}


contract Broker is BrokerInterface {
    address public factory;

    function Broker(address _factory) {
        factory = _factory;
    }

    uint _id;

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

    /*
     *  Internal utility
     */
    function inStatus(uint id, Status status) internal returns (bool) {
        return _getRequest(id).status == status;
    }

    function anyStatus(uint id, Status s1, Status s2) internal returns (bool) {
        var status = _getRequest(id).status;
        return (status == s1 || status == s2);
    }

    function requireStatus(uint id, Status status) internal {
        if (!inStatus(id, status)) throw;
    }

    function requireStatus(uint id, Status s1, Status s2) internal {
        if (!anyStatus(id, s1, s2)) throw;
    }

    function serializeRequest(Request request) internal returns (bytes32 argsHash,
                                                                 bytes32 resultHash,
                                                                 address requester,
                                                                 address executable,
                                                                 uint creationBlock,
                                                                 Status status) {
        argsHash = request.argsHash;
        resultHash = request.resultHash;
        requester = request.requester;
        executable = request.executable;
        creationBlock = request.creationBlock;
        status = request.status;

        return (argsHash, resultHash, requester, executable, creationBlock, status);
    }

    function serializeAnswer(Answer answer) internal returns (bytes32 resultHash,
                                                              address submitter,
                                                              uint creationBlock) {
        resultHash = answer.resultHash;
        submitter = answer.submitter;
        creationBlock = answer.creationBlock;

        return (resultHash, submitter, creationBlock);
    }

    /*
     *  Public getters
     */
    function getRequest(uint id) constant returns (bytes32 argsHash,
                                                   bytes32 resultHash,
                                                   address requester,
                                                   address executable,
                                                   uint creationBlock,
                                                   Status status) {
        var request = _getRequest(id);

        return serializeRequest(request);
    }

    function getRequestArgs(uint id) constant returns (bytes) {
        var request = _getRequest(id);

        return request.args;
    }

    function getInitialAnswer(uint id) constant returns (bytes32 resultHash,
                                                         address submitter,
                                                         uint creationBlock) {
        var request = _getRequest(id);

        (resultHash, submitter, creationBlock) = serializeAnswer(request.initialAnswer);

        return (resultHash, submitter, creationBlock);
    }

    function getInitialAnswerResult(uint id) constant returns (bytes) {
        return _getRequest(id).initialAnswer.result;
    }

    function getChallengeAnswer(uint id) constant returns (bytes32 resultHash,
                                                                     address submitter,
                                                                     uint creationBlock) {
        var request = _getRequest(id);

        (resultHash, submitter, creationBlock) = serializeAnswer(request.challengeAnswer);
        return (resultHash, submitter, creationBlock);
    }

    function getChallengeAnswerResult(uint id) constant returns (bytes) {
        return _getRequest(id).challengeAnswer.result;
    }

    /*
     *  Public API.
     */
    function requestExecution(bytes args) public returns (uint) {
        _id += 1;

        var request = requests[_id];
        request.id = _id;
        request.requester = msg.sender;
        request.args = args;
        request.argsHash = sha3(args);
        request.creationBlock = block.number;

        Created(_id, request.argsHash);

        return _id;
    }

    function answerRequest(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        // Already answered
        if (request.initialAnswer.submitter != 0x0) throw;

        // TODO: require deposit big enough for a full computation (from
        // factory contract)

        request.initialAnswer.submitter = msg.sender;
        request.initialAnswer.result = result;
        request.initialAnswer.resultHash = sha3(result);
        request.initialAnswer.creationBlock = block.number;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, request.initialAnswer.resultHash);
    }

    function challengeAnswer(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        var resultHash = sha3(result);

        // No initial answer
        if (request.initialAnswer.submitter == 0x0) throw;

        // Duplicate answers
        if (request.initialAnswer.resultHash == resultHash) throw;

        // TODO: require deposit big enough for a full computation (from
        // factory contract)

        request.initialAnswer.submitter = msg.sender;
        request.initialAnswer.result = result;
        request.initialAnswer.resultHash = resultHash;
        request.initialAnswer.creationBlock = block.number;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, resultHash);
    }

    // Deploy the execution contract.
    function deployExecutable(uint id) public returns (address) {
        var request = requests[_getRequest(id).id];

        // executable already deployed
        if (request.executable == 0x0) throw;

        request.executable = FactoryInterface(factory).build(request.args);

        return request.executable;
    }
}
