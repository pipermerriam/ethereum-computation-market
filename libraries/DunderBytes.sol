library DunderBytes {
    function toUInt(bytes v) constant returns (uint result) {
        for (uint i = 0; i < v.length; i++) {
            result += uint(v[i]) * 2 ** (8 * i);
        }
        return result;
    }

    function extractUint(bytes v, uint startIdx, uint endIdx) constant returns (uint result) {
        if (startIdx >= endIdx || endIdx >= v.length) throw;
        for (uint i = startIdx; i < endIdx; i++) {
            result += uint(v[i]) * 2 ** (8 * (i - startIdx));
        }
        return result;
    }
}
