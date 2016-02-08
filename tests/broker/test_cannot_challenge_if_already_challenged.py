import pytest

from ethereum.tester import TransactionFailed

deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_cannot_answer_if_already_answered(deploy_client,
                                           deploy_broker_contract,
                                           deployed_contracts, get_log_data,
                                           deploy_coinbase, contracts, denoms,
                                           StatusEnum,
                                           get_computation_request):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    expected = "\x01\x02\x03\x04\x05\x06\x07"

    _id = get_computation_request(
        broker, "abcdefg",
        initial_answer=expected,
        challenge_answer="wrong",
    )

    assert broker.getRequest(_id)[5] == StatusEnum.NeedsResolution

    deposit_amount = broker.getRequiredDeposit("wrong")

    assert deposit_amount > 0

    with pytest.raises(TransactionFailed):
        broker.challengeAnswer(_id, "duplicate", value=deposit_amount)
