import pytest

from ethereum.tester import TransactionFailed

deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_submitting_initial_answer(deploy_client, deploy_broker_contract,
                                   deployed_contracts, get_log_data,
                                   deploy_coinbase, contracts, denoms,
                                   StatusEnum, get_computation_request):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    _id = get_computation_request(
        broker, "abcdefg",
        initial_answer=expected,
    )

    assert broker.getRequest(_id)[5] == StatusEnum.WaitingForResolution

    deposit_amount = broker.getRequiredDeposit("abcdefg")

    assert deposit_amount > 0

    with pytest.raises(TransactionFailed):
        broker.answerRequest(_id, expected, value=deposit_amount)
