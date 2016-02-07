import sha3


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_initializing_dispute_gas_is_covered(deploy_client, get_computation_request,
                                             deploy_broker_contract, deployed_contracts,
                                             get_log_data, StatusEnum):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    _id = get_computation_request(
        broker, "abcdefg",
        initial_answer="wrong",
        challenge_answer=expected,
    )

    assert broker.getRequest(_id)[5] == StatusEnum.NeedsResolution

    i_dispute_txn_hash = broker.initializeDispute(_id)
    i_dispute_txn_receipt = deploy_client.wait_for_transaction(i_dispute_txn_hash)

    assert broker.getRequest(_id)[5] == StatusEnum.Resolving

    gas_log_data = get_log_data(broker.GasReimbursement, i_dispute_txn_hash)

    gas_reimbursement = gas_log_data['value']
    gas_actual = int(i_dispute_txn_receipt['gasUsed'], 16)

    assert gas_reimbursement >= gas_actual
    assert gas_reimbursement - gas_actual < 10000
