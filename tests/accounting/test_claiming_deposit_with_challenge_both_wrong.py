
deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_reclaiming_deposit_with_both_wrong(deploy_client,
                                            get_computation_request,
                                            deploy_broker_contract,
                                            deployed_contracts, get_log_data,
                                            StatusEnum, deploy_coinbase):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    deposit_amount = broker.getRequiredDeposit("abcdefg");

    _id = get_computation_request(
        broker, "abcdefg",
        initial_answer="wrong",
        initial_answer_deposit=deposit_amount + 1,
        challenge_answer="also_wrong",
        challenge_deposit=deposit_amount + 2,
        initialize_dispute=True,
        perform_execution=True,
        finalize=True,
    )

    assert broker.getRequest(_id)[5] == StatusEnum.Finalized

    reclaim_txn_h = broker.reclaimDeposit(_id)
    reclaim_txn_r = deploy_client.wait_for_transaction(reclaim_txn_h)

    deposit_log_data = get_log_data(broker.DepositReturned, reclaim_txn_h)

    assert len(deposit_log_data) == 2

    gas_reimbursments = broker.getRequest(_id)[8]

    d_a, d_b = deposit_log_data

    assert d_a['value'] == deposit_amount + 1 - gas_reimbursments / 2 - gas_reimbursments % 2
    assert d_a['to'] == deploy_coinbase

    assert d_b['value'] == deposit_amount + 2 - gas_reimbursments / 2
    assert d_b['to'] == deploy_coinbase
