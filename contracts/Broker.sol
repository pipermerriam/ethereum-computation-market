import {FactoryInterface} from "contracts/Factory.sol";
import {ExecutableInterface} from "contracts/Execution.sol";
import {AccountingLib} from "libraries/AccountingLib.sol";


contract BrokerInterface {
    using AccountingLib for address;

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
        FirmResolution,
        Finalized
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
        uint softResolutionBlocks;
        uint baseGasPrice;
        uint basePayment;
        uint gasReimbursements;
        Status status;
        Answer initialAnswer;
        Answer challengeAnswer;
    }

    // ~1 day.
    uint constant DEFAULT_SOFT_RESOLUTION_BLOCKS = 5080;

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
    function getRequestResult(uint id) constant returns (bytes result);
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
    event Execution(uint nTimes, bool isFinished);

    /*
     *  Public API
     */
    // Request a computation to be done.
    function requestExecution(bytes args, uint softResolutionBlocks) public returns (uint);

    // Submit an answer to a requested computation.
    function answerRequest(uint id, bytes result) public;

    // Challenge the answer to a question.
    function challengeAnswer(uint id, bytes result) public;

    // Dispute resolution
    function initializeDispute(uint id) public returns (address);
}


contract Broker is BrokerInterface {
    FactoryInterface public factory;

    function Broker(address _factory) {
        factory = FactoryInterface(_factory);
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
    function inStatus(Request request, Status status) internal returns (bool) {
        return request.status == status;
    }

    function anyStatus(Request request, Status s1, Status s2) internal returns (bool) {
        return (request.status == s1 || request.status == s2);
    }

    function requireStatus(Request request, Status status) internal {
        if (!inStatus(request, status)) throw;
    }

    function requireStatus(Request request, Status s1, Status s2) internal {
        if (!anyStatus(request, s1, s2)) throw;
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

    function gasScalar(uint basePrice) constant returns (uint) {
        /*
        *  Return a number between 0 - 200 to scale the donation based on the
        *  gas price set for the calling transaction as compared to the gas
        *  price of the requesting transaction.
        *
        *  - number approaches zero as the transaction gas price goes
        *  above the gas price recorded when the call was requesting.
        *
        *  - the number approaches 200 as the transaction gas price
        *  drops under the price recorded when the call was requesting.
        *
        *  This encourages lower gas costs as the lower the gas price
        *  for the executing transactions, the higher the payout to the
        *  caller.
        */
        if (tx.gasprice > basePrice) {
            return 100 * basePrice / tx.gasprice;
        }
        else {
            return 200 - 100 * basePrice / (2 * basePrice - tx.gasprice);
        }
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

    function getRequestResult(uint id) constant returns (bytes) {
        var request = _getRequest(id);

        return request.result;
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
        return requestExecution(args, DEFAULT_SOFT_RESOLUTION_BLOCKS);
    }

    function requestExecution(bytes args, uint softResolutionBlocks) public returns (uint) {
        _id += 1;

        var request = requests[_id];
        request.id = _id;
        request.requester = msg.sender;
        request.args = args;
        request.argsHash = sha3(args);
        request.creationBlock = block.number;
        request.softResolutionBlocks = softResolutionBlocks;
        request.baseGasPrice = tx.gasprice;
        request.basePayment = msg.value;

        Created(_id, request.argsHash);

        return _id;
    }

    function answerRequest(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request, Status.Pending);

        // Already answered
        if (request.initialAnswer.submitter != 0x0) throw;

        // TODO: require deposit big enough for a full computation (from
        // factory contract)

        request.initialAnswer.submitter = msg.sender;
        request.initialAnswer.result = result;
        request.initialAnswer.resultHash = sha3(result);
        request.initialAnswer.creationBlock = block.number;

        // Update the state
        request.status = Status.WaitingForResolution;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, request.initialAnswer.resultHash);
    }

    function softResolveAnswer(uint id) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request, Status.WaitingForResolution);

        // too early to resolve (unless your the requester)
        if (msg.sender != request.requester && block.number < request.creationBlock + request.softResolutionBlocks) throw;

        // Update the state
        request.status = Status.SoftResolution;
    }

    function challengeAnswer(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request, Status.WaitingForResolution);

        var resultHash = sha3(result);

        // No initial answer
        if (request.initialAnswer.submitter == 0x0) throw;

        // Duplicate answers
        if (request.initialAnswer.resultHash == resultHash) throw;

        // TODO: require deposit big enough for a full computation (from
        // factory contract)

        request.challengeAnswer.submitter = msg.sender;
        request.challengeAnswer.result = result;
        request.challengeAnswer.resultHash = resultHash;
        request.challengeAnswer.creationBlock = block.number;

        // Update the state
        request.status = Status.NeedsResolution;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, resultHash);
    }

    // TODO: derive this value
    uint constant INITIALIZE_DISPUTE_GAS = 0;

    function initializeDispute(uint id) public returns (address) {
        uint startGas = msg.gas;
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request, Status.NeedsResolution);

        // executable already deployed
        if (request.executable != 0x0) throw;

        // no answer
        if (request.initialAnswer.submitter == 0x0) throw;

        // no challenge
        if (request.challengeAnswer.submitter == 0x0) throw;

        request.executable = factory.build(request.args);

        // Update the state
        request.status = Status.Resolving;

        // record the gas that was used.
        msg.sender.sendRobust(gasScalar(request.baseGasPrice) * tx.gasprice * (msg.gas - startGas + INITIALIZE_DISPUTE_GAS) / 100);

        return request.executable;
    }

    // TODO: derive this value.
    uint constant EXECUTE_EXECUTABLE_GAS = 0;

    function executeExecutable(uint id, uint nTimes) public returns (uint i, bool isFinished) {
        var startGas = msg.gas;

        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request, Status.Resolving);

        // no executable.
        if (request.executable == 0x0) throw;

        var executable = ExecutableInterface(request.executable);

        // execution has been completed.
        if (!executable.isFinished()) {
            i = executable.executeN(nTimes);

            // Something is wrong.  It should have executed at least one round.
            if (i == 0) throw;
        }

        isFinished = executable.isFinished();

        Execution(i, isFinished);

        if (isFinished) {
            request.status = Status.FirmResolution;
        }

        // reimburse for the gas that was used.
        msg.sender.sendRobust(gasScalar(request.baseGasPrice) * tx.gasprice * (msg.gas - startGas + EXECUTE_EXECUTABLE_GAS) / 100);

        return (i, isFinished);
    }

    bytes __outputCallbackStorage;

    function __outputCallback(uint length) public {
        if (msg.data.length <= 4 + length) throw;

        __outputCallbackStorage.length = 0;

        for (uint i = 0; i < length; i++) {
            __outputCallbackStorage.push(msg.data[i + 4 + 32]);
        }
    }

    // TODO: derive this value
    uint constant FINALIZE_GAS = 0;

    function finalize(uint id) public returns (bytes32) {
        var startGas = msg.gas;
        address paymentTo;
        var request = requests[_getRequest(id).id];

        requireStatus(request, Status.FirmResolution, Status.SoftResolution);

        var executable = ExecutableInterface(request.executable);

        if (request.executable != 0x0) {
            request.resultHash = executable.getOutputHash();

            if (!executable.requestOutput(bytes4(sha3("__outputCallback(uint256)")))) throw;
            if (sha3(__outputCallbackStorage) != request.resultHash) throw;

            request.result = __outputCallbackStorage;

            if (request.initialAnswer.resultHash == request.resultHash) {
                request.initialAnswer.isVerified = true;
                paymentTo = request.initialAnswer.submitter;
            } else if (request.challengeAnswer.resultHash == request.resultHash) {
                request.challengeAnswer.isVerified = true;
                paymentTo = request.challengeAnswer.submitter;
            } else {
                // If neither answers are correct the requester gets their
                // payment back.
                paymentTo = request.requester;
            }
        }
        else {
            request.result = request.initialAnswer.result;
            request.resultHash = request.initialAnswer.resultHash;
            paymentTo = request.initialAnswer.submitter;
        }

        paymentTo.sendRobust(request.basePayment);

        request.status = Status.Finalized;

        // reimburse for the gas that was used.
        reimburseGas(request, msg.sender, startGas, FINALIZE_GAS);

        return request.resultHash;
    }

    function reimburseGas(Request request, address to, uint startGas, uint extraGas) internal {
        var gasReimbursement = gasScalar(request.baseGasPrice) * tx.gasprice / 100;
        gasReimbursement *= (msg.gas - startGas + FINALIZE_GAS);

        if (msg.sender.sendRobust(gasReimbursement)) {
            request.gasReimbursements += gasReimbursement;
        }
    }

    function reclaimDeposit(uint id) {
    }
}
