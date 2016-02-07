import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_initial_answer_requires_deposit(deploy_client, deploy_broker_contract,
                                         deployed_contracts, get_log_data,
                                         deploy_coinbase, contracts, denoms,
                                         StatusEnum):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    request_txn_hash = broker.requestExecution("abcdefg", value=10 * denoms.ether)
    request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

    request_event_data = get_log_data(broker.Created, request_txn_hash)

    _id = request_event_data['id']

    assert broker.getRequest(_id)[5] == StatusEnum.Pending

    deposit_amount = broker.getRequiredDeposit("abcdefg")

    assert deposit_amount > 0

    with pytest.raises(TransactionFailed):
        broker.answerRequest(_id, "dummy", value=deposit_amount - 1)
