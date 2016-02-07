import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_creating_request_for_execution(deploy_client, deploy_broker_contract,
                                        deployed_contracts, get_log_data,
                                        deploy_coinbase, StatusEnum, denoms):
    broker = deploy_broker_contract(deployed_contracts.BuildByteArrayFactory._meta.address)

    request_txn_hash = broker.requestExecution("abcdefg", value=10 * denoms.ether)
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    event_data = get_log_data(broker.Created, request_txn_hash)

    _id = event_data['id']

    req_data = broker.getRequest(_id)

    assert req_data[0] == sha3.sha3_256("abcdefg").digest()
    assert req_data[1] == "\x00" * 32
    assert req_data[2] == deploy_coinbase
    assert req_data[3] == "0x0000000000000000000000000000000000000000"
    assert req_data[4] == int(request_txn_receipt['blockNumber'], 16)
    assert req_data[5] == StatusEnum.Pending
    assert req_data[6] == 10 * denoms.ether
    assert req_data[7] == broker.getDefaultSoftResolutionBlocks()
