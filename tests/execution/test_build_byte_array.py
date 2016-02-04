deployed_contracts = []


def test_build_byte_array(deploy_client, contracts, deploy_contract):
    bba = deploy_contract(contracts.BuildByteArray, ("abc",))

    assert bba.output() == ''

    e1_txn_hash = bba.execute()
    e1_txn_receipt = deploy_client.wait_for_transaction(e1_txn_hash)

    assert bba.output() == ''

    e2_txn_hash = bba.execute()
    e2_txn_receipt = deploy_client.wait_for_transaction(e2_txn_hash)

    assert bba.output() == ''

    e3_txn_hash = bba.execute()
    e3_txn_receipt = deploy_client.wait_for_transaction(e3_txn_hash)

    assert bba.isFinal() is True
    assert bba.output() == "\x01\x02\x03"
