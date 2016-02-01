import pytest

import math


@pytest.fixture
def deploy_computation_contract(deploy_client):
    from populus.contracts import (
        deploy_contract,
    )
    from populus.utils import (
        get_contract_address_from_txn,
    )

    def _deploy_computation_contract(ContractClass, input_bytes):
        deploy_txn_hash = deploy_contract(
            deploy_client,
            ContractClass,
            constructor_args=(
                input_bytes,
            ),
            gas=int(deploy_client.get_max_gas() * 0.95),
        )

        c_address = get_contract_address_from_txn(deploy_client, deploy_txn_hash, 180)
        c = ContractClass(c_address, deploy_client)
        return c
    return _deploy_computation_contract


deployed_contracts = []


def test_build_byte_array(deploy_client, contracts, deploy_computation_contract):
    arst = deploy_computation_contract(contracts.BuildByteArray, "abc")

    assert arst.output() == ''

    e1_txn_hash = arst.execute()
    e1_txn_receipt = deploy_client.wait_for_transaction(e1_txn_hash)

    assert arst.output() == ''

    e2_txn_hash = arst.execute()
    e2_txn_receipt = deploy_client.wait_for_transaction(e2_txn_hash)

    assert arst.output() == ''

    e3_txn_hash = arst.execute()
    e3_txn_receipt = deploy_client.wait_for_transaction(e3_txn_hash)

    assert arst.isFinal() is True
    assert arst.output() == "\x00\x01\x02"


@pytest.mark.parametrize(
    'idx,fib_n',
    zip(
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
        (1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89),
    ),
)
def test_fibonacci(deploy_client, contracts, deploy_computation_contract, idx, fib_n):
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

    assert bytes_to_int(int_to_bytes(12345)) == 12345
    assert bytes_to_int(int_to_bytes(256)) == 256
    assert bytes_to_int(int_to_bytes(255)) == 255

    assert int_to_bytes(bytes_to_int('aa')) == 'aa'
    assert int_to_bytes(bytes_to_int('\xff\xff')) == '\xff\xff'

    arst = deploy_computation_contract(contracts.Fibonacci, int_to_bytes(idx))

    assert arst.toBytes(255) == int_to_bytes(255)
    assert arst.toBytes(256) == int_to_bytes(256)
    assert arst.toBytes(12345) == int_to_bytes(12345)

    assert arst.fromBytes('aa') == bytes_to_int('aa')
    assert arst.fromBytes('\xff\xff') == bytes_to_int('\xff\xff')

    assert arst.output() == ''

    for _ in range(idx + 1):
        txn_hash = arst.execute()
        txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    assert arst.isFinal() is True
    assert arst.output() == int_to_bytes(fib_n)
