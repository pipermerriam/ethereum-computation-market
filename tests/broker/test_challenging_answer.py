import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_challenging_answer(deploy_client, deploy_broker_contract,
                            deployed_contracts, get_log_data,
                            deploy_coinbase, contracts):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

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
