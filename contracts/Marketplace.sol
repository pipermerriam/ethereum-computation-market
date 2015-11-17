import "libraries/ComputationLib.sol";


contract Marketplace {
        function register_computation_contract(address verifier_address) returns (address) {
                Computation computation = new Computation(verifier_address);
                return address(computation);
        }
}
