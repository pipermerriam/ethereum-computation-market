import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_fibonacci_factory(deploy_client, deploy_broker_contract,
                           deployed_contracts, get_log_data, deploy_coinbase):
    broker = deploy_broker_contract(deployed_contracts.BuildByteArrayFactory._meta.address)

    request_txn_hash = broker.requestExecution("abcdefg")
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    block = deploy_client.get_block_by_number(int(request_txn_receipt['blockNumber'], 16))

    event_data = get_log_data(broker.Created, request_txn_hash)

    _id = event_data['id']

    req_data = broker.getRequest(_id)
    assert req_data[0] == sha3.sha3_256("abcdefg").digest()
    assert req_data[1] == deploy_coinbase
    assert req_data[2] == "0x0000000000000000000000000000000000000000"
    assert req_data[3] == int(block['timestamp'], 16)
    assert req_data[4] == 0

    req_args = broker.getRequestArgs(_id)
    assert req_args == "abcdefg"
