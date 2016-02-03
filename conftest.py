import pytest


@pytest.fixture(scope="session")
def denoms():
    from ethereum.utils import denoms as ether_denoms
    return ether_denoms


@pytest.fixture
def deploy_computation_contract(deploy_client, contracts):
    from populus.deployment import (
        deploy_contracts,
    )

    def _deploy_computation_contract(ContractClass, input_bytes):
        deployed_contracts = deploy_contracts(
            deploy_client=deploy_client,
            contracts=contracts,
            contracts_to_deploy=[ContractClass.__name__],
            constructor_args={
                ContractClass.__name__: (input_bytes,),
            }
        )

        return getattr(deployed_contracts, ContractClass.__name__)
    return _deploy_computation_contract


@pytest.fixture
def get_built_contract_address(deploy_client, contracts):
    def _get_built_contract_address(txn_hash, contract_type=None):
        F = contracts.FactoryInterface(None, deploy_client)
        build_logs = F.Constructed.get_transaction_logs(txn_hash)
        assert len(build_logs) == 1
        build_data = F.Constructed.get_log_data(build_logs[0])
        if contract_type is None:
            return build_data['addr']
        else:
            return contract_type(build_data['addr'], deploy_client)
    return _get_built_contract_address
