deploy_contracts = [
    "FibonacciFactory",
]


def test_fibonacci_factory_total_gas_numbers(deploy_client, contracts,
                                             deployed_contracts,
                                             get_built_contract_address,
                                             math_tools):
    factory = deployed_contracts.FibonacciFactory

    assert len(deploy_client.get_code(factory._meta.address)) > 5

    fib_299 = 222232244629420445529739893461909967206666939096499764990979600

    build_txn_hash = factory.build(math_tools.int_to_bytes(299))

    fib = get_built_contract_address(build_txn_hash, contracts.Fibonacci)

    assert fib.output() == ''

    gas_expected = factory.totalGas(math_tools.int_to_bytes(299))

    gas_used = []

    while not fib.isFinished():
        txn_hash = fib.executeN()
        txn_receipt = deploy_client.wait_for_transaction(txn_hash)

        gas_used.append(int(txn_receipt['gasUsed'], 16))

    gas_actual = sum(gas_used)

    assert gas_expected > gas_actual
    assert gas_expected - gas_actual < 5000000

    assert fib.output() == math_tools.int_to_bytes(fib_299)
