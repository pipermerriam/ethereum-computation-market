import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_challenging_answer(deploy_client, deploy_broker_contract,
                            deployed_contracts, get_log_data,
                            deploy_coinbase, contracts, StatusEnum, denoms):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    request_txn_hash = broker.requestExecution("abcdefg", value=10 * denoms.ether)
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    request_event_data = get_log_data(broker.Created, request_txn_hash)

    _id = request_event_data['id']

    assert broker.getRequest(_id)[5] == StatusEnum.Pending

    deposit_amount = broker.getRequiredDeposit("abcdefg")

    assert deposit_amount > 0

    i_answer_txn_hash = broker.answerRequest(_id, "wrong", value=deposit_amount)
    i_answer_txn_receipt = deploy_client.wait_for_transaction(i_answer_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.WaitingForResolution

    i_answer_data = set(broker.getInitialAnswer(_id))

    assert deploy_coinbase in i_answer_data
    assert sha3.sha3_256("wrong").digest() in i_answer_data
    assert int(i_answer_txn_receipt['blockNumber'], 16) in i_answer_data
    assert broker.getInitialAnswerResult(_id) == "wrong"

    c_answer_txn_hash = broker.challengeAnswer(_id, expected, value=deposit_amount)
    c_answer_txn_receipt = deploy_client.wait_for_transaction(c_answer_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.NeedsResolution

    c_answer_data = set(broker.getChallengeAnswer(_id))

    assert deploy_coinbase in c_answer_data
    assert sha3.sha3_256(expected).digest() in c_answer_data
    assert int(c_answer_txn_receipt['blockNumber'], 16) in c_answer_data
    assert broker.getChallengeAnswerResult(_id) == expected
