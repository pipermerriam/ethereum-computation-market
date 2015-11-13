import pytest


@pytest.fixture(scope="session")
def denoms():
    from ethereum.utils import denoms as ether_denoms
    return ether_denoms


@pytest.fixture(scope="module")
def deploy_computation_contract(deploy_client, contracts, deploy_coinbase, denoms):
    from populus.contracts import (
        deploy_contract,
    )
    from populus.utils import (
        get_contract_address_from_txn,
    )

    def _deploy_computation_contract(verifier_contract):
        deploy_txn_hash = deploy_contract(
            deploy_client,
            contracts.Computation,
            constructor_args=(
                verifier_contract._meta.address,
            ),
            gas=int(deploy_client.get_max_gas() * 0.95),
            value=denoms.ether,
        )

        computation_address = get_contract_address_from_txn(deploy_client, deploy_txn_hash, 180)
        computation = contracts.Computation(computation_address, deploy_client)
        return computation
    return _deploy_computation_contract


@pytest.fixture(scope="module")
def Computation(contracts):
    return contracts.Computation


@pytest.fixture(scope="module")
def Request(contracts):
    return contracts.Request


@pytest.fixture(scope="module")
def get_request(Computation, Request, deploy_client):
    def _get_request(txn_hash):
        _comp = Computation('not-real', deploy_client)
        request_created_logs = _comp.RequestCreated.get_transaction_logs(txn_hash)
        assert len(request_created_logs) == 1
        request_created_data = _comp.RequestCreated.get_log_data(request_created_logs[0])

        request_address = request_created_data['requestAddress']
        request = Request(request_address, deploy_client)
        return request
    return _get_request
