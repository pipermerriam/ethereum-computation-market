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


@pytest.fixture
def get_computation_request(deploy_client, get_log_data, StatusEnum, denoms):
    def _get_computation_request(broker, args="abcdefg", initial_answer=None,
                                 soft_resolve=False, challenge_answer=None,
                                 initialize_dispute=False,
                                 perform_execution=False, finalize=False):
        request_txn_hash = broker.requestExecution(args, value=10 * denoms.ether)
        request_txn_receipt = deploy_client.wait_for_transaction(request_txn_hash)

        request_event_data = get_log_data(broker.Created, request_txn_hash)

        _id = request_event_data['id']

        assert broker.getRequest(_id)[5] == StatusEnum.Pending

        if initial_answer is None:
            return _id

        deposit_amount = broker.getRequiredDeposit("abcdefg")

        assert deposit_amount > 0

        i_answer_txn_hash = broker.answerRequest(_id, initial_answer, value=deposit_amount)
        i_answer_txn_receipt = deploy_client.wait_for_transaction(i_answer_txn_hash)

        assert broker.getRequest(_id)[5] == StatusEnum.WaitingForResolution

        if challenge_answer is not None:
            c_answer_txn_hash = broker.challengeAnswer(_id, challenge_answer, value=deposit_amount)
            c_answer_txn_receipt = deploy_client.wait_for_transaction(c_answer_txn_hash)

            assert broker.getRequest(_id)[5] == StatusEnum.NeedsResolution

            if initialize_dispute:
                i_dispute_txn_hash = broker.initializeDispute(_id)
                i_dispute_txn_receipt = deploy_client.wait_for_transaction(i_dispute_txn_hash)

                if perform_execution:
                    while broker.getRequest(_id)[5] == StatusEnum.Resolving:
                        exec_txn_hash = broker.executeExecutable(_id, 0)
                        exec_txn_receipt = deploy_client.wait_for_transaction(exec_txn_hash)

                        execute_log_data = get_log_data(broker.Execution, exec_txn_hash)

                    assert broker.getRequest(_id)[5] == StatusEnum.FirmResolution
        elif soft_resolve:
            soft_res_txn_h = broker.softResolveAnswer()
            soft_res_txn_r = deploy_client.wait_for_transaction(soft_res_txn_h)

            assert broker.getRequest(_id)[5] == StatusEnum.SoftResolution
        else:
            return _id

        if finalize:
            finalize_txn_hash = broker.finalize(_id)
            finalize_txn_receipt = deploy_client.wait_for_transaction(finalize_txn_hash)

        return _id
    return _get_computation_request


@pytest.fixture
def math_tools():
    import math

    def int_to_bytes(int_v):
        len = int(math.ceil(math.log(int_v + 1, 2) / 8))
        return ''.join(
            chr((2 ** 8 - 1) & (int_v / 2 ** (8 * i)))
            for i in range(len)
        )

    def bytes_to_int(bytes_v):
        return sum(
            ord(b) * 2 ** (8 * idx)
            for idx, b in enumerate(bytes_v)
        )

    tools = {
        'int_to_bytes': staticmethod(int_to_bytes),
        'bytes_to_int': staticmethod(bytes_to_int),
    }
    return type('math_tools', (object,), tools)
