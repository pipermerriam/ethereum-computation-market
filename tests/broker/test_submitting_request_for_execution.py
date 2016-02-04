import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_creating_request_for_execution(deploy_client, deploy_broker_contract,
                                        deployed_contracts, get_log_data,
                                        deploy_coinbase):
    broker = deploy_broker_contract(deployed_contracts.BuildByteArrayFactory._meta.address)

    request_txn_hash = broker.requestExecution("abcdefg")
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    event_data = get_log_data(broker.Created, request_txn_hash)

    _id = event_data['id']

    req_data = set(broker.getRequest(_id))

    assert sha3.sha3_256("abcdefg").digest() in req_data
    assert "\x00" * 32 in req_data
    assert deploy_coinbase in req_data
    assert "0x0000000000000000000000000000000000000000" in req_data
    assert int(request_txn_receipt['blockNumber'], 16) in req_data
    assert 0 in req_data
