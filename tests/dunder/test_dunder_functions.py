import pytest

import math


deployed_contracts = [
    "TestDunder",
]


def bytes_to_int(bytes_v):
    return sum(
        ord(b) * 2 ** (8 * idx)
        for idx, b in enumerate(bytes_v)
    )


def int_to_bytes(int_v):
    len = int(math.ceil(math.log(int_v + 1, 2) / 8))
    return ''.join(
        chr((2 ** 8 - 1) & (int_v / 2 ** (8 * i)))
        for i in range(len)
    )


@pytest.mark.parametrize(
    "uint_v,bytes_v",
    (
        (12345, "90"),
        (256, "\x00\x01"),
        (255, "\xff"),
        (1, "\x01"),
    )
)
def test_uint_to_bytes(deployed_contracts, bytes_v, uint_v):
    dunder = deployed_contracts.TestDunder

    assert bytes_to_int(int_to_bytes(uint_v)) == uint_v
    assert dunder.toUInt(int_to_bytes(uint_v)) == uint_v
    assert dunder.toUInt(dunder.toBytes(uint_v)) == uint_v
    assert bytes_to_int(dunder.toBytes(uint_v)) == uint_v

    assert dunder.toBytes(uint_v) == bytes_v
    assert int_to_bytes(uint_v) == bytes_v


@pytest.mark.parametrize(
    "bytes_v,uint_v",
    (
        ("aa", 24929),
        ("\x00\x01", 256),
        ("\xff", 255),
        ("\x01", 1),
    )
)
def test_bytes_to_uint(deployed_contracts, bytes_v, uint_v):
    dunder = deployed_contracts.TestDunder

    assert int_to_bytes(bytes_to_int(bytes_v)) == bytes_v
    assert dunder.toBytes(bytes_to_int(bytes_v)) == bytes_v
    assert dunder.toBytes(dunder.toUInt(bytes_v)) == bytes_v
    assert dunder.toBytes(bytes_to_int(bytes_v)) == bytes_v

    assert dunder.toUInt(bytes_v) == uint_v
    assert bytes_to_int(bytes_v) == uint_v
