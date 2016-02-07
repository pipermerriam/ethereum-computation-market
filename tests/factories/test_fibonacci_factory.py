deploy_contracts = [
    "FibonacciFactory",
]


def test_fibonacci_factory(deploy_client, contracts, deployed_contracts,
                           get_built_contract_address, math_tools):
    factory = deployed_contracts.FibonacciFactory

    assert len(deploy_client.get_code(factory._meta.address)) > 5

    build_txn_hash = factory.build(math_tools.int_to_bytes(10))

    fib = get_built_contract_address(build_txn_hash, contracts.Fibonacci)

    assert fib.output() == ''

    txn_hash = fib.executeN()
    txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    assert fib.isFinal() is True
    assert fib.output() == math_tools.int_to_bytes(89)
