import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_finalizing_unchallenged_answer(deploy_client, deploy_broker_contract,
                                        deployed_contracts, get_log_data,
                                        deploy_coinbase, contracts, denoms,
                                        StatusEnum):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    request_txn_hash = broker.requestExecution("abcdefg", 40, value=10 * denoms.ether)
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    request_event_data = get_log_data(broker.Created, request_txn_hash)

    _id = request_event_data['id']

    req_data = broker.getRequest(_id)
    assert req_data[5] == StatusEnum.Pending
    assert req_data[7] == 40

    deposit_amount = broker.getRequiredDeposit("abcdefg")

    assert deposit_amount > 0

    answer_txn_hash = broker.answerRequest(_id, expected, value=deposit_amount)
    answer_txn_receipt = deploy_client.wait_for_transaction(answer_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.WaitingForResolution

    answer_data = broker.getInitialAnswer(_id)

    assert answer_data[0] == sha3.sha3_256(expected).digest()
    assert answer_data[1] == deploy_coinbase
    assert answer_data[2] == int(answer_txn_receipt['blockNumber'], 16)
    assert answer_data[3] is False

    deploy_client.wait_for_block(req_data[4] + req_data[7])

    resolve_txn_h = broker.softResolveAnswer(_id)
    resolve_txn_r = deploy_client.wait_for_transaction(resolve_txn_h)

    assert broker.getRequest(_id)[5] == StatusEnum.SoftResolution

    finalize_txn_h = broker.finalize(_id)
    finalize_txn_r = deploy_client.wait_for_transaction(finalize_txn_h)

    assert broker.getRequest(_id)[5] == StatusEnum.Finalized
