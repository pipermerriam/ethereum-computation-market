import {Executable} from "contracts/Execution.sol";
import {DunderBytes} from "libraries/DunderBytes.sol";
import {DunderUIntToBytes} from "libraries/DunderUInt.sol";


contract BuildByteArray is Executable {
    function BuildByteArray(bytes args) {
        input = args;
    }

    function step(uint step, bytes args) constant returns (bytes result, bool isFinal) {
        result = new bytes(step == 0 ? 1 : args.length + 1);

        result[result.length - 1] = byte(step);
        if (step != 0) {
            for (uint i = 0; i < args.length; i++) {
                result[i] = args[i];
            }
        }

        isFinal = (result.length >= input.length);

        return (result, isFinal);
    }
}


contract Fibonacci is Executable, DunderUIntToBytes {
    using DunderBytes for bytes;

    function Fibonacci(bytes args) {
        input = args;
    }

    function step(uint step, bytes args) constant returns (bytes result, bool isFinal) {
        if (step == 0 || step == 1) {
            result = toBytes(1);
        }
        else {
            // TODO: this should not access previous state but should instead
            // store this state using a longer bytes string at each step.
            var n_1 = stateHistory[step - 1].result.toUInt();
            var n_2 = stateHistory[step - 2].result.toUInt();
            result = toBytes(n_1 + n_2);
        }

        isFinal = step >= input.toUInt();
        return (result, isFinal);
    }
}
