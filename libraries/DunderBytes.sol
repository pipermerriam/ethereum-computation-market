library DunderBytes {
    function toUInt(bytes v) constant returns (uint result) {
        for (uint i = 0; i < v.length; i++) {
            result += uint(v[i]) * 2 ** (8 * i);
        }
        return result;
    }
}
