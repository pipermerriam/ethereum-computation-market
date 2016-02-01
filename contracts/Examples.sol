import {ComputationBase} from "contracts/Computation.sol";


contract BuildByteArray is ComputationBase {
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


contract Fibonacci is ComputationBase {
    function Fibonacci(bytes args) {
        input = args;
    }

    function fromBytes(bytes v) constant returns (uint result) {
        for (uint i = 0; i < v.length; i++) {
            result += uint(v[i]) * 2 ** (8 * i);
        }
        return result;
    }

    function toBytes(uint v) constant returns (bytes result) {
        uint len;
        while (2 ** (8 * len) <= v) {
            len += 1;
        }
        result = new bytes(len);
        for (uint i = 0; i < len; i++) {
            result[i] = byte(uint8(v));
            v /= 0xff;
        }
        return result;
    }

    function step(uint step, bytes args) constant returns (bytes result, bool isFinal) {
        if (step == 0 || step == 1) {
            result = toBytes(1);
        }
        else {
            var n_1 = fromBytes(stateHistory[step - 1].result);
            var n_2 = fromBytes(stateHistory[step - 2].result);
            result = toBytes(n_1 + n_2);
        }

        isFinal = step >= fromBytes(input);
        return (result, isFinal);
    }
}
