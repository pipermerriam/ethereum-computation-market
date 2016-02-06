import pytest


@pytest.fixture(scope="session")
def denoms():
    from ethereum.utils import denoms as ether_denoms
    return ether_denoms


@pytest.fixture
def deploy_contract(deploy_client, contracts):
    from populus.deployment import (
        deploy_contracts,
    )

    def _deploy_contract(ContractClass, constructor_args):
        deployed_contracts = deploy_contracts(
            deploy_client=deploy_client,
            contracts=contracts,
            contracts_to_deploy=[ContractClass.__name__],
            constructor_args={
                ContractClass.__name__: constructor_args,
            }
        )

        contract = getattr(deployed_contracts, ContractClass.__name__)
        assert deploy_client.get_code(contract._meta.address)
        return contract
    return _deploy_contract


@pytest.fixture
def deploy_broker_contract(contracts, deploy_contract, deploy_client):
    def _deploy_broker_contract(factory_address):
        broker = deploy_contract(contracts.Broker, (factory_address,))
        return broker
    return _deploy_broker_contract


@pytest.fixture
def get_log_data(deploy_client, contracts):
    def _get_log_data(event, txn_hash):
        event_logs = event.get_transaction_logs(txn_hash)
        assert len(event_logs) == 1
        event_data = event.get_log_data(event_logs[0])
        return event_data
    return _get_log_data


@pytest.fixture
def get_built_contract_address(contracts, deploy_client, get_log_data):
    def _get_built_contract_address(txn_hash, contract_type=None):
        F = contracts.FactoryInterface(None, deploy_client)
        build_data = get_log_data(F.Constructed, txn_hash)
        if contract_type is None:
            return build_data['addr']
        else:
            return contract_type(build_data['addr'], deploy_client)
    return _get_built_contract_address


@pytest.fixture
def StatusEnum():
    enum_values = {
        'Pending': 0,
        'WaitingForResolution': 1,
        'NeedsResolution': 2,
        'Resolving': 3,
        'SoftResolution': 4,
        'FirmResolution': 5,
        'Finalized': 6,
    }
    return type("StatusEnum", (object,), enum_values)
