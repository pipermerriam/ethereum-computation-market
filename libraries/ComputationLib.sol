import "libraries/RequestLib.sol";


contract Computation {
        address public verifier;
        uint public minimum_gas;
        uint public maximum_stack_depth;

        mapping (address => bool) public knownRequest;

        function Computation(address _verifier, uint _minimum_gas) {
                verifier = _verifier;
                minimum_gas = _minimum_gas;
        }

        event RequestCreated(address requestAddress);

        function get_default_payment() returns (uint) {
                return 1 ether;
        }

        function get_default_fee() returns (uint) {
                return 1 finney;
        }

        function initiate_request(bytes input) {
                initiate_request(input, get_default_payment(), get_default_fee());
        }

        function initiate_request(bytes input, uint payment) {
                initiate_request(input, payment, get_default_fee());
        }

        function initiate_request(bytes input, uint payment, uint fee) {
                // Insufficient funds.
                if (msg.value < payment + fee) throw;
                Request request = new Request.value(msg.value)(msg.sender, input, payment, fee);
                RequestCreated(address(request));
        }
}

