import {Executable} from "contracts/Execution.sol";
import {FactoryBase} from "contracts/Factory.sol";
import {DunderBytes} from "libraries/DunderBytes.sol";
import {DunderUIntToBytes} from "libraries/DunderUInt.sol";


contract TestFactory is FactoryBase {
    function TestFactory() FactoryBase("ipfs://test", "solc 9000", "--fake") {
    }
}


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


contract BuildByteArrayFactory is TestFactory {
    function build(bytes args) public returns (address) {
        var buildByteArray = new BuildByteArray(args);
        return address(buildByteArray);
    }
}


contract Fibonacci is Executable, DunderUIntToBytes {
    using DunderBytes for bytes;

    function Fibonacci(bytes args) {
        input = args;
    }

    function step(uint step, bytes args) constant returns (bytes result, bool isFinal) {
        uint i;
        bytes memory fib_n;

        if (step == 0 || step == 1) {
            fib_n = toBytes(1);
        }
        else {
            // TODO: this should not access previous state but should instead
            // store this state using a longer bytes string at each step.
            var n_1 = args.extractUint(0, 31);
            var n_2 = args.extractUint(32, 63);
            fib_n = toBytes(n_1 + n_2);
        }

        isFinal = step >= input.toUInt();

        if (isFinal) {
            result = fib_n;
        }
        else if (step == 0) {
            result = new bytes(64);
            for (i = 0; i < fib_n.length; i++) {
                result[32 + i] = fib_n[i];
            }
        }
        else {
            result = new bytes(64);
            for (i = 0; i < 32; i++) {
                result[i] = args[i + 32];
                if (i < fib_n.length) {
                    result[32 + i] = fib_n[i];
                }
            }
        }

        return (result, isFinal);
    }
}
