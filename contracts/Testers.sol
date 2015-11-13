contract TestStartsWithA {
    function compute(bytes input) constant returns (bool) {
        if (input.length == 0) {
            return false;
        }
        return (input[0] == 'a' || input[0] == 'A');
        return true;
    }

    function request_output(bytes input) {
        report_output(msg.sender, compute(input));
    }

    function report_output(address to, bool output) internal {
        to.call(bytes4(sha3("register_on_chain_output()")), output);
    }
}
