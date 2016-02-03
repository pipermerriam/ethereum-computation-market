import pytest

import math


deploy_contracts = [
    "FibonacciFactory",
]


def int_to_bytes(int_v):
    len = int(math.ceil(math.log(int_v + 1, 2) / 8))
    return ''.join(
        chr((2 ** 8 - 1) & (int_v / 2 ** (8 * i)))
        for i in range(len)
    )


def test_fibonacci_factory(deploy_client, contracts, deployed_contracts,
                           get_built_contract_address):
    factory = deployed_contracts.FibonacciFactory

    assert len(deploy_client.get_code(factory._meta.address)) > 5

    build_txn_hash = factory.build(int_to_bytes(10))

    fib = get_built_contract_address(build_txn_hash, contracts.Fibonacci)

    assert fib.output() == ''

    txn_hash = fib.executeN()
    txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    assert fib.isFinal() is True
    assert fib.output() == int_to_bytes(89)
