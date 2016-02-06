/// @title Accounting Lib - Accounting utilities
/// @author Piper Merriam - <pipermerriam@gmail.com>
library AccountingLib {
    /*
     *  Address: 0x89efe605e9ecbe22849cd85d5449cc946c26f8f3
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
