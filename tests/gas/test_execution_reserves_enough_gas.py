deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_dispute_execution_reserves_enough_gas(deploy_client, get_computation_request,
                                               deploy_broker_contract, deployed_contracts,
                                               get_log_data, StatusEnum, math_tools):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = ''.join(chr(i % 256) for i in range(500))

    _id = get_computation_request(
        broker, "a" * 500,
        initial_answer="wrong",
        challenge_answer=expected,
        initialize_dispute=True,
    )

    while broker.getRequest(_id)[5] == StatusEnum.Resolving:
        exec_txn_hash = broker.executeExecutable(_id, 0)
        exec_txn_receipt = deploy_client.wait_for_transaction(exec_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.FirmResolution
