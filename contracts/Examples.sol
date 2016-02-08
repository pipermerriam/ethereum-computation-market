import {DunderBytes} from "libraries/DunderBytes.sol";
import {DunderUIntToBytes} from "libraries/DunderUInt.sol";
import {ExecutableBase} from "contracts/Execution.sol";
import {StatelessFactory} from "contracts/Factory.sol";


contract TestFactory is StatelessFactory {
    function TestFactory() StatelessFactory("ipfs://test", "solc 9000", "--fake") {
    }
}


contract BuildByteArray is ExecutableBase {
    function BuildByteArray(bytes args) ExecutableBase(args) {
    }

    function step(uint currentStep, bytes _state) public returns (bytes result, bool) {
        result = new bytes(currentStep == 1 ? 1 : _state.length + 1);

        result[result.length - 1] = byte(currentStep);
        if (currentStep > 1) {
            for (uint i = 0; i < _state.length; i++) {
                result[i] = _state[i];
            }
        }

        return (result, (result.length >= input.length));
    }
}


contract BuildByteArrayFactory is TestFactory {
    function _build(bytes args) internal returns (address) {
        var buildByteArray = new BuildByteArray(args);
        return address(buildByteArray);
    }

    int constant STEP_GAS = 60000;

    function totalGas(bytes args) constant returns(int) {
        return STEP_GAS * int(args.length);
    }
}


contract Fibonacci is ExecutableBase, DunderUIntToBytes {
    using DunderBytes for bytes;

    function Fibonacci(bytes args) ExecutableBase(args) {
    }

    function step(uint currentStep, bytes _state) public returns (bytes result, bool) {
        uint i;
        bytes memory fib_n;

        if (currentStep == 1 || currentStep == 2) {
            fib_n = toBytes(1);
        }
        else {
            // TODO: this should not access previous state but should instead
            // store this state using a longer bytes string at each step.
            var n_1 = _state.extractUint(0, 31);
            var n_2 = _state.extractUint(32, 63);
            fib_n = toBytes(n_1 + n_2);
        }

        if (currentStep > input.toUInt()) {
            result = fib_n;
        }
        else if (currentStep == 1) {
            result = new bytes(64);
            for (i = 0; i < fib_n.length; i++) {
                result[32 + i] = fib_n[i];
            }
        }
        else {
            result = new bytes(64);
            for (i = 0; i < 32; i++) {
                result[i] = _state[i + 32];
                if (i < fib_n.length) {
                    result[32 + i] = fib_n[i];
                }
            }
        }

        return (result, (currentStep > input.toUInt()));
    }
}


contract FibonacciFactory is TestFactory {
    using DunderBytes for bytes;

    function _build(bytes args) internal returns (address) {
        var fibonacci = new Fibonacci(args);
        return address(fibonacci);
    }

    int constant STEP_1_GAS = 100000;
    int constant STEP_N_GAS = 80000;
    int constant STEP_LAST_GAS = 66000;

    function totalGas(bytes args) constant returns(int) {
        int numSteps = int(args.toUInt());
        if (numSteps == 1) return STEP_1_GAS;
        return STEP_1_GAS + (numSteps - 1) * (STEP_N_GAS) + STEP_LAST_GAS;
    }
}
