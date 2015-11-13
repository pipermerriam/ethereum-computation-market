import pytest


deploy_contracts = [
    "TestStartsWithA",
]

TRUE_AS_BYTES32 = chr(0) * 31 + chr(1)
FALSE_AS_BYTES32 = chr(0) * 32

@pytest.mark.parametrize(
    "input_bytes,off_chain_output_bytes,on_chain_output_bytes,should_overturn",
    (
        ('abcdefg', TRUE_AS_BYTES32, TRUE_AS_BYTES32, False),
        ('abcdefg', FALSE_AS_BYTES32, TRUE_AS_BYTES32, True),
        ('ABCDEFG', TRUE_AS_BYTES32, TRUE_AS_BYTES32, False),
        ('ABCDEFG', FALSE_AS_BYTES32, TRUE_AS_BYTES32, True),
        ('xyz', TRUE_AS_BYTES32, FALSE_AS_BYTES32, True),
        ('xyz', FALSE_AS_BYTES32, FALSE_AS_BYTES32, False),
        ('XYZ', TRUE_AS_BYTES32, FALSE_AS_BYTES32, True),
        ('XYZ', FALSE_AS_BYTES32, FALSE_AS_BYTES32, False),
    )
)
def test_computation_request(deploy_computation_contract, deploy_client,
                             deployed_contracts, get_request, denoms,
                             input_bytes, off_chain_output_bytes,
                             on_chain_output_bytes, should_overturn,
                             ):
    comp = deploy_computation_contract(deployed_contracts.TestStartsWithA)
    req_txn_hash = comp.initiate_request(input_bytes)
    req = get_request(req_txn_hash)

    assert req.state() == 0
    assert req.off_chain_output() == ''
    assert req.on_chain_output() == ''

    off_chain_register_txn = req.register_off_chain_output(
        off_chain_output_bytes,
        value=denoms.ether,
    )
    deploy_client.wait_for_transaction(off_chain_register_txn)

    assert req.state() == 1
    assert req.off_chain_output() == off_chain_output_bytes
    assert req.on_chain_output() == ''

    assert req.was_challenged() is False
    assert req.was_overturned() is False

    challenge_txn = req.challenge_output(value=denoms.ether)
    deploy_client.wait_for_transaction(challenge_txn)

    assert req.state() == 2
    assert req.off_chain_output() == off_chain_output_bytes
    assert req.on_chain_output() == on_chain_output_bytes

    assert req.was_challenged() is True
    assert req.was_overturned() is should_overturn
