contract Computation {
        address public verifier;

        mapping (address => bool) public knownRequest;

        function Computation(address _verifier) {
                verifier = _verifier;
        }

        event RequestCreated(address requestAddress);

        function initiate_request(bytes input) {
                Request request = new Request(msg.sender, input);
                RequestCreated(address(request));
        }
}
