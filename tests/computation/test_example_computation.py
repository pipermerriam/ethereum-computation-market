import pytest

import math


@pytest.fixture
def deploy_computation_contract(deploy_client, contracts):
    from populus.deployment import (
        deploy_contracts,
    )

    def _deploy_computation_contract(ContractClass, input_bytes):
        deployed_contracts = deploy_contracts(
            deploy_client=deploy_client,
            contracts=contracts,
            contracts_to_deploy=[ContractClass.__name__],
            constructor_args={
                ContractClass.__name__: (input_bytes,),
            }
        )

        return getattr(deployed_contracts, ContractClass.__name__)
    return _deploy_computation_contract


deployed_contracts = []


def test_build_byte_array(deploy_client, contracts, deploy_computation_contract):
    bba = deploy_computation_contract(contracts.BuildByteArray, "abc")

    assert bba.output() == ''

    e1_txn_hash = bba.execute()
    e1_txn_receipt = deploy_client.wait_for_transaction(e1_txn_hash)

    assert bba.output() == ''

    e2_txn_hash = bba.execute()
    e2_txn_receipt = deploy_client.wait_for_transaction(e2_txn_hash)

    assert bba.output() == ''

    e3_txn_hash = bba.execute()
    e3_txn_receipt = deploy_client.wait_for_transaction(e3_txn_hash)

    assert bba.isFinal() is True
    assert bba.output() == "\x00\x01\x02"


def int_to_bytes(int_v):
    len = int(math.ceil(math.log(int_v + 1, 2) / 8))
    return ''.join(
        chr((2 ** 8 - 1) & (int_v / 2 ** (8 * i)))
        for i in range(len)
    )


@pytest.mark.parametrize(
    'idx,fib_n',
    zip(
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
        (1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89),
    ),
)
def test_fibonacci(deploy_client, contracts, deploy_computation_contract, idx, fib_n):
    fib = deploy_computation_contract(contracts.Fibonacci, int_to_bytes(idx))

    assert fib.output() == ''

    states = []

    for _ in range(idx + 1):
        txn_hash = fib.execute()
        txn_receipt = deploy_client.wait_for_transaction(txn_hash)
        states.append(fib.getState())

    assert fib.isFinal() is True
    assert fib.output() == int_to_bytes(fib_n)
