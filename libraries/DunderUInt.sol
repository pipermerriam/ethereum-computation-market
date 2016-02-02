contract DunderUIntToBytes {
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
}
