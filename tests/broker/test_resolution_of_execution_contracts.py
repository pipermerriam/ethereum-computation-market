import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_resolving_resolution(deploy_client, deploy_broker_contract,
                              deployed_contracts, get_log_data,
                              deploy_coinbase, contracts, StatusEnum):
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

    i_answer_txn_hash = broker.answerRequest(_id, "wrong")
    i_answer_txn_receipt = deploy_client.wait_for_transaction(i_answer_txn_hash)

    i_answer_data = set(broker.getInitialAnswer(_id))

    assert deploy_coinbase in i_answer_data
    assert sha3.sha3_256("wrong").digest() in i_answer_data
    assert int(i_answer_txn_receipt['blockNumber'], 16) in i_answer_data
    assert broker.getInitialAnswerResult(_id) == "wrong"

    c_answer_txn_hash = broker.challengeAnswer(_id, expected)
    c_answer_txn_receipt = deploy_client.wait_for_transaction(c_answer_txn_hash)

    c_answer_data = set(broker.getChallengeAnswer(_id))

    assert deploy_coinbase in c_answer_data
    assert sha3.sha3_256(expected).digest() in c_answer_data
    assert int(c_answer_txn_receipt['blockNumber'], 16) in c_answer_data
    assert broker.getChallengeAnswerResult(_id) == expected

    assert broker.getRequest(_id)[3] == '0x0000000000000000000000000000000000000000'
    assert broker.getRequest(_id)[5] == StatusEnum.NeedsResolution

    i_dispute_txn_hash = broker.initializeDispute(_id)
    i_dispute_txn_receipt = deploy_client.wait_for_transaction(i_dispute_txn_hash)

    i_dispute_log_data = get_log_data(factory.Constructed, i_dispute_txn_hash)

    assert i_dispute_log_data['addr'] in broker.getRequest(_id)[3]
    assert broker.getRequest(_id)[5] == StatusEnum.Resolving

    while broker.getRequest(_id)[5] == StatusEnum.Resolving:
        exec_txn_hash = broker.executeExecutable(_id, 0)
        exec_txn_receipt = deploy_client.wait_for_transaction(exec_txn_hash)

        execute_log_data = get_log_data(broker.Execution, exec_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.FirmResolution

    resolve_txn_hash = broker.finalize(_id)
    resolve_txn_receipt = deploy_client.wait_for_transaction(resolve_txn_hash)

    final_req_data = broker.getRequest(_id)
    assert final_req_data[5] == StatusEnum.Finalized
    assert final_req_data[1] == sha3.sha3_256(expected).digest()
    assert broker.getRequestResult(_id) == expected
