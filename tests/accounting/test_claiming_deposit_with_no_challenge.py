deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_reclaiming_deposit_with_no_challenge(deploy_client, get_computation_request,
                                              deploy_broker_contract, deployed_contracts,
                                              get_log_data, StatusEnum, deploy_coinbase):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    deposit_amount = broker.getRequiredDeposit("abcdefg");

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    _id = get_computation_request(
        broker, "abcdefg",
        initial_answer=expected,
        initial_answer_deposit=deposit_amount + 1,
        soft_resolve=True,
        finalize=True,
    )

    assert broker.getRequest(_id)[5] == StatusEnum.Finalized

    reclaim_txn_h = broker.reclaimDeposit(_id)
    reclaim_txn_r = deploy_client.wait_for_transaction(reclaim_txn_h)

    deposit_log_data = get_log_data(broker.DepositReturned, reclaim_txn_h)

    assert deposit_log_data['value'] == deposit_amount + 1
    assert deposit_log_data['to'] == deploy_coinbase
