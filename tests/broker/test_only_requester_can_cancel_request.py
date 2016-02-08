import pytest

from ethereum.tester import TransactionFailed
deploy_contracts = [
    "BuildByteArrayFactory",
]


def test_cannot_cancel_if_not_requester(deploy_client, get_computation_request,
                                        deploy_broker_contract,
                                        deployed_contracts, get_log_data,
                                        StatusEnum, accounts):
    factory = deployed_contracts.BuildByteArrayFactory
    broker = deploy_broker_contract(factory._meta.address)

    _id = get_computation_request(
        broker, "abcdefg",
    )

    with pytest.raises(TransactionFailed):
        broker.cancelRequest(_id, _from=accounts[1])
