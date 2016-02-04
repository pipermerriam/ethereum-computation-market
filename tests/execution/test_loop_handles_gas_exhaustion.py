import math


deployed_contracts = []


def int_to_bytes(int_v):
    len = int(math.ceil(math.log(int_v + 1, 2) / 8))
    return ''.join(
        chr((2 ** 8 - 1) & (int_v / 2 ** (8 * i)))
        for i in range(len)
    )


def bytes_to_int(bytes_v):
    return sum(
        ord(b) * 2 ** (8 * idx)
        for idx, b in enumerate(bytes_v)
    )


def test_gas_exhaustion_is_handled(deploy_client, contracts,
                                   deploy_contract):
    fib = deploy_contract(contracts.Fibonacci, (int_to_bytes(60),))

    assert fib.output() == ''

    txn_hash = fib.executeN(gas=3141592)
    txn_receipt = deploy_client.wait_for_transaction(txn_hash)

    gas_limit = 3141592
    gas_used = int(txn_receipt['gasUsed'], 16)

    assert not fib.isFinal()
    assert abs(gas_used - gas_limit) < 42000

    current_step = fib.currentStep()

    while not fib.isFinal():
        loop_txn_hash = fib.executeN(gas=3141592)
        loop_txn_receipt = deploy_client.wait_for_transaction(loop_txn_hash)
        if fib.currentStep() > current_step:
            current_step = fib.currentStep()
        else:
            raise ValueError("step did not advance")

    assert fib.isFinal() is True
    assert fib.output() == int_to_bytes(2504730781961)
