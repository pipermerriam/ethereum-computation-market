import {DunderBytes} from "libraries/DunderBytes.sol";
import {DunderUIntToBytes} from "libraries/DunderUInt.sol";


contract TestDunder is DunderUIntToBytes {
    using DunderBytes for bytes;

    function toUInt(bytes v) constant returns (uint) {
        return v.toUInt();
    }
}
