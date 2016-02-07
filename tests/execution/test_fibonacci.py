import pytest


deployed_contracts = []


@pytest.mark.parametrize(
    'idx,fib_n',
    zip(
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
        (1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89),
    ),
)
def test_fibonacci_single_execution(deploy_client, contracts,
                                    deploy_contract, idx, fib_n, math_tools):
    fib = deploy_contract(contracts.Fibonacci, (math_tools.int_to_bytes(idx),))

    assert fib.output() == ''

    for _ in range(idx + 1):
        txn_hash = fib.execute()
        txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    assert fib.isFinal() is True
    assert fib.output() == math_tools.int_to_bytes(fib_n)


@pytest.mark.parametrize(
    'idx,fib_n',
    zip(
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
        (1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89),
    ),
)
def test_fibonacci_looped_execution(deploy_client, contracts,
                                    deploy_contract, idx, fib_n):
    fib = deploy_contract(contracts.Fibonacci, (math_tools.int_to_bytes(idx),))

    assert fib.output() == ''

    txn_hash = fib.executeN()
    txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    assert fib.isFinal() is True
    assert fib.output() == math_tools.int_to_bytes(fib_n)
