import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_fibonacci_factory(deploy_client, deploy_broker_contract,
                           deployed_contracts, get_log_data, deploy_coinbase,
                           contracts):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    executor_txn_hash = factory.build("abcdefg")
    executor_txn_receipt = deploy_client.wait_for_transaction(executor_txn_hash)

    factory_event_data = get_log_data(factory.Constructed, executor_txn_hash)

    executor_addr = factory_event_data['addr']
    executor = contracts.BuildByteArray(executor_addr, deploy_client)

    while not executor.isFinal():
        deploy_client.wait_for_transaction(executor.executeN())

    expected = executor.output()
    assert expected == "\x01\x02\x03\x04\x05\x06\x07"

    request_txn_hash = broker.requestExecution("abcdefg")
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    request_event_data = get_log_data(broker.Created, request_txn_hash)

    _id = request_event_data['id']

    req_data = broker.getRequest(_id)
    assert req_data[4] == 0

    answer_txn_hash = broker.answerRequest(_id, expected)
    answer_txn_receipt = deploy_client.wait_for_transaction(answer_txn_hash)

    block = deploy_client.get_block_by_number(int(answer_txn_receipt['blockNumber'], 16))

    answer_event_data = get_log_data(broker.Answered, answer_txn_hash)
    answer_idx = answer_event_data['idx']

    answer_data = broker.getAnswer(_id, answer_idx)

    assert answer_data[0] == deploy_coinbase
    assert answer_data[1] == sha3.sha3_256(expected).digest()
    assert answer_data[2] == int(block['timestamp'], 16)
