deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_initializing_dispute_gas_is_covered(deploy_client, get_computation_request,
                                             deploy_broker_contract, deployed_contracts,
                                             get_log_data, StatusEnum):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    _id = get_computation_request(
        broker, "abcdefg",
    )

    cancel_txn_hash = broker.cancelRequest(_id)
    cancel_txn_receipt = deploy_client.wait_for_transaction(cancel_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.Cancelled
    assert broker.getRequest(_id)[6] == 0
