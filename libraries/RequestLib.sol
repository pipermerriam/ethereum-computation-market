contract ComputationAPI {
    address public verifier;
    bytes4 public abiSignature;
}

contract VerifierAPI {
    function request_output(bytes input) public;
}

contract Request {
        ComputationAPI computation;
        VerifierAPI verifier;
        
        // Pending   => (Fullfilled,)
        // Fullfilled => (Finalized, Pending)
        // Finalized => null
        enum State {
                Pending,
                Fullfilled,
                Finalized
        }

        bytes public input;
        address public requester;

        bytes public off_chain_output;
        bytes public on_chain_output;
        address public reporter;

        bool public was_challenged;
        bool public was_overturned;

        uint public bond;
        State public state;

        modifier onlystate(State targetstate) {
            if (state != targetstate) throw;
            _
        }

        modifier bonded(uint value) {
            if (msg.value < value) throw;
            _
        }

        function Request(address _requester, bytes _input) {
            requester = _requester;
            computation = ComputationAPI(msg.sender);
            verifier = VerifierAPI(computation.verifier());

            input = _input;
        }

        uint MINIMUM_BOND = 1 ether;

        function cmp(bytes _a, bytes _b) internal returns (bool) {
            if (_a.length != _b.length) {
                return false;
            }
            for (uint i = 0; i < _a.length; i++) {
                if (_a[i] != _b[i]) {
                    return false;
                }
            }
            return true;
        }

        function challenge_output()
            onlystate(State.Fullfilled)
            bonded(MINIMUM_BOND)
        {
                was_challenged = true;
                verifier.request_output(input);
                if (cmp(off_chain_output, on_chain_output)) {
                    // Off chain was correct.
                }
                else {
                    // Off chain was incorrect.
                    was_overturned = true;
                }
                state = State.Finalized;
        }

        function finalize()
            onlystate(State.Fullfilled)
        {
            // TODO: bonds
            state = State.Finalized;
        }

        function register_off_chain_output(bytes _output)
            onlystate(State.Pending)
            bonded(MINIMUM_BOND)
        {
                bond = msg.value;
                reporter = msg.sender;
                off_chain_output = _output;
                state = State.Fullfilled;
        }

        function result() 
            onlystate(State.Finalized)
            returns (bytes)
        {
                if (was_overturned) {
                    return on_chain_output;
                }
                else {
                    return off_chain_output;
                }
        }

        function register_on_chain_output()
            onlystate(State.Fullfilled)
        {
            on_chain_output.length = msg.data.length - 4;
            if (msg.data.length > 4) {
                    for (uint i = 0; i < on_chain_output.length; i++) {
                            on_chain_output[i] = msg.data[i + 4];
                    }
            }
        }
}
