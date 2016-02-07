import {FactoryInterface} from "contracts/Factory.sol";
import {ExecutableInterface} from "contracts/Execution.sol";


contract BrokerInterface {
    struct Answer {
        address submitter;
        bytes result;
        bytes32 resultHash;
        uint creationBlock;
        uint depositAmount;
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
     *  - Finalized: This request has a result.  Deposits may now be returned
     *    and payment issued.
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
        uint payment;
        uint gasReimbursements;
        uint requiredDeposit;
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
                                                   Status status,
                                                   uint payment,
                                                   uint softResolutionBlocks);
    function getRequestArgs(uint id) constant returns (bytes result);
    function getRequestResult(uint id) constant returns (bytes result);
    function getInitialAnswer(uint id) constant returns (bytes32 resultHash,
                                                         address submitter,
                                                         uint creationBlock,
                                                         bool isVerified);

    function getInitialAnswerResult(uint id) constant returns (bytes);
    function getChallengeAnswer(uint id) constant returns (bytes32 resultHash,
                                                           address submitter,
                                                           uint creationBlock,
                                                           bool isVerified);
    function getChallengeAnswerResult(uint id) constant returns (bytes);

    function getRequiredDeposit(bytes args) constant returns (uint);

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

    // Advance the on chain execution of the contract
    function executeExecutable(uint id, uint nTimes) public returns (uint i, bool isFinished);

    // Finalize the result
    function finalize(uint id) public returns (bytes32);
}


contract Accounting {
    /*
     *  Accounting Functions
     */

    uint constant DEFAULT_SEND_GAS = 100000;

    function sendRobust(address toAddress, uint value) public returns (bool) {
        if (msg.gas < DEFAULT_SEND_GAS) {
            return sendRobust(toAddress, value, msg.gas);
        }
        return sendRobust(toAddress, value, DEFAULT_SEND_GAS);
    }

    function sendRobust(address toAddress, uint value, uint maxGas) public returns (bool) {
        if (value > 0 && !toAddress.send(value)) {
            // Potentially sending money to a contract that
            // has a fallback function.  So instead, try
            // tranferring the funds with the call api.
            if (!toAddress.call.gas(maxGas).value(value)()) {
                return false;
            }
        }
        return true;
    }
}


contract Broker is BrokerInterface, Accounting {
    FactoryInterface public factory;

    function Broker(address _factory) {
        factory = FactoryInterface(_factory);
    }

    uint _id;

    function getRequiredDeposit(bytes args) constant returns (uint) {
        // TODO: this should come from the factory? or the executable?
        return 10 ether;
    }

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
    function requireStatus(Status status, Status s1) internal {
        if (status != s1) throw;
    }

    function requireStatus(Status status, Status s1, Status s2) internal {
        if (status != s1 && status != s2) throw;
    }

    function serializeRequest(Request request) internal returns (bytes32 argsHash,
                                                                 bytes32 resultHash,
                                                                 address requester,
                                                                 address executable,
                                                                 uint creationBlock,
                                                                 Status status,
                                                                 uint payment,
                                                                 uint softResolutionBlocks) {
        argsHash = request.argsHash;
        resultHash = request.resultHash;
        requester = request.requester;
        executable = request.executable;
        creationBlock = request.creationBlock;
        status = request.status;
        payment = request.payment;
        softResolutionBlocks = request.softResolutionBlocks;

        return (argsHash, resultHash, requester, executable, creationBlock,
                status, payment, softResolutionBlocks);
    }

    function serializeAnswer(Answer answer) internal returns (bytes32 resultHash,
                                                              address submitter,
                                                              uint creationBlock,
                                                              bool isVerified) {
        resultHash = answer.resultHash;
        submitter = answer.submitter;
        creationBlock = answer.creationBlock;
        isVerified = answer.isVerified;

        return (resultHash, submitter, creationBlock, isVerified);
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

    function remainingGasFund(uint id) constant returns (uint) {
        var request = _getRequest(id);
        
        // No gas available unless answer was challenged.
        if (request.executable == 0x0) return 0;

        // Already spent all gas
        if (request.gasReimbursements > request.requiredDeposit) return 0;

        return request.requiredDeposit - request.gasReimbursements;
    }

    function min(uint a, uint b) constant returns (uint) {
        if (a <= b) return a;
        return b;
    }

    event GasReimbursement(address to, uint value);

    function reimburseGas(uint id, address to, uint startGas, uint extraGas) internal {
        var request = requests[id];
        var gasReimbursement = gasScalar(request.baseGasPrice) * tx.gasprice / 100;
        gasReimbursement *= (startGas - msg.gas) + extraGas;

        gasReimbursement = min(gasReimbursement, remainingGasFund(id));

        // Log it.
        GasReimbursement(msg.sender, gasReimbursement);

        if (sendRobust(msg.sender, gasReimbursement)) {
            request.gasReimbursements += gasReimbursement;
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
                                                   Status status,
                                                   uint payment,
                                                   uint softResolutionBlocks) {
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
                                                         uint creationBlock,
                                                         bool isVerified) {
        var request = _getRequest(id);

        return serializeAnswer(request.initialAnswer);
    }

    function getInitialAnswerResult(uint id) constant returns (bytes) {
        return _getRequest(id).initialAnswer.result;
    }

    function getChallengeAnswer(uint id) constant returns (bytes32 resultHash,
                                                           address submitter,
                                                           uint creationBlock,
                                                           bool isVerified) {
        var request = _getRequest(id);

        return serializeAnswer(request.challengeAnswer);
    }

    function getChallengeAnswerResult(uint id) constant returns (bytes) {
        return _getRequest(id).challengeAnswer.result;
    }

    function getDefaultSoftResolutionBlocks() constant returns (uint) {
        return DEFAULT_SOFT_RESOLUTION_BLOCKS;
    }

    /*
     *  Public API.
     */
    function requestExecution(bytes args) public returns (uint) {
        return requestExecution(args, getDefaultSoftResolutionBlocks());
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
        request.payment = msg.value;
        request.requiredDeposit = getRequiredDeposit(args);

        Created(_id, request.argsHash);

        return _id;
    }

    function answerRequest(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request.status, Status.Pending);

        // Already answered
        if (request.initialAnswer.submitter != 0x0) throw;

        // Insufficient deposit
        if (msg.value < request.requiredDeposit) throw;

        request.initialAnswer.submitter = msg.sender;
        request.initialAnswer.result = result;
        request.initialAnswer.resultHash = sha3(result);
        request.initialAnswer.creationBlock = block.number;
        request.initialAnswer.depositAmount = msg.value;

        // Update the state
        request.status = Status.WaitingForResolution;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, request.initialAnswer.resultHash);
    }

    function softResolveAnswer(uint id) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request.status, Status.WaitingForResolution);

        // too early to resolve (unless your the requester)
        if (msg.sender != request.requester && block.number < request.creationBlock + request.softResolutionBlocks) throw;

        // Update the state
        request.status = Status.SoftResolution;
    }

    function challengeAnswer(uint id, bytes result) public {
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request.status, Status.WaitingForResolution);

        // Insufficient deposit
        if (msg.value < request.requiredDeposit) throw;

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
        request.challengeAnswer.depositAmount = msg.value;

        // Update the state
        request.status = Status.NeedsResolution;

        // Log that a new answer was submitted.
        AnswerSubmitted(id, resultHash);
    }

    // TODO: derive this value
    uint constant INITIALIZE_DISPUTE_GAS = 60000;

    function initializeDispute(uint id) public returns (address) {
        uint startGas = msg.gas;
        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request.status, Status.NeedsResolution);

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
        reimburseGas(request.id, msg.sender, startGas, INITIALIZE_DISPUTE_GAS);

        return request.executable;
    }

    // TODO: derive this value.
    uint constant EXECUTE_EXECUTABLE_GAS = 0;

    function executeExecutable(uint id, uint nTimes) public returns (uint i, bool isFinished) {
        var startGas = msg.gas;

        var request = requests[_getRequest(id).id];

        // Check status
        requireStatus(request.status, Status.Resolving);

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
        reimburseGas(request.id, msg.sender, startGas, EXECUTE_EXECUTABLE_GAS);

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

        requireStatus(request.status, Status.FirmResolution, Status.SoftResolution);

        var executable = ExecutableInterface(request.executable);

        if (request.executable != 0x0) {
            // If this was verified on-chain, then retrieve the computed answer
            // and evaluate the submitted answers.
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
            // If this was resolved with no challenge, then use the
            // submitted asnwer.
            request.result = request.initialAnswer.result;
            request.resultHash = request.initialAnswer.resultHash;
            paymentTo = request.initialAnswer.submitter;
        }

        // Send the payment to the appropriate party.
        sendRobust(paymentTo, request.payment);

        // Update the status.
        request.status = Status.Finalized;

        // reimburse for the gas that was used.
        reimburseGas(request.id, msg.sender, startGas, FINALIZE_GAS);

        return request.resultHash;
    }

    function reclaimDeposit(uint id) public {
        // TODO: test this functionality.
        var request = requests[_getRequest(id).id];

        if (msg.sender == request.initialAnswer.submitter) {
            if (request.initialAnswer.depositAmount == 0) return;

            if (request.initialAnswer.resultHash != request.resultHash) {
                // If they answered incorrectly see if they are responsible for
                // all or half of the gas costs.
                if (request.challengeAnswer.resultHash == request.resultHash) {
                    request.initialAnswer.depositAmount -= request.gasReimbursements;
                } else {
                    // The initial answerer is responsible for any odd
                    // remainder values if the gas remibursements were an odd
                    // value that doesn't evenly divide.
                    request.initialAnswer.depositAmount -= request.gasReimbursements / 2 + request.gasReimbursements % 2;
                }
            }

            // Send back their deposit.
            if (sendRobust(msg.sender, request.initialAnswer.depositAmount)) {
                request.initialAnswer.depositAmount = 0;
            }
        }
        else if (msg.sender == request.challengeAnswer.submitter) {
            if (request.challengeAnswer.depositAmount == 0) return;

            if (request.challengeAnswer.resultHash != request.resultHash) {
                // If they answered incorrectly see if they are responsible for
                // all or half of the gas costs.
                if (request.initialAnswer.resultHash == request.resultHash) {
                    request.challengeAnswer.depositAmount -= request.gasReimbursements;
                } else {
                    request.challengeAnswer.depositAmount -= request.gasReimbursements / 2;
                }
            }

            // Send back their deposit.
            if (sendRobust(msg.sender, request.challengeAnswer.depositAmount)) {
                request.challengeAnswer.depositAmount = 0;
            }
        }
    }
}
