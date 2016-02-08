contract FactoryInterface {
    function build(bytes args) public returns (address);
    function _build(bytes args) internal returns (address);

    event Constructed(address addr, bytes32 argsHash);

    function isStateless() constant returns (bool);

    // return negative number to indicate unknown.
    function totalGas(bytes args) constant returns(int);
}


contract FactoryBase is FactoryInterface {
    // The URI where the source code for this contract can be found.
    string public sourceURI;
    // The compiler version used to compile this contract.
    string public compilerVersion;
    // The compile flags used during compilation.
    string public compilerFlags;

    bool public stateless;

    function FactoryBase(string _sourceURI, string _compilerVersion, string _compilerFlags) {
        sourceURI = _sourceURI;
        compilerVersion = _compilerVersion;
        compilerFlags = _compilerFlags;
    }

    function build(bytes args) public returns (address addr) {
        addr = _build(args);
        Constructed(addr, sha3(args));
        return addr;
    }

    function isStateless() constant returns (bool) {
        return stateless;
    }

    // returning negative numbers indicates unknown.
    function totalGas(bytes args) constant returns(int) { return -1; }
}


contract StatelessFactory is FactoryBase {
    function StatelessFactory(string _sourceURI, string _compilerVersion, string _compilerFlags)
             FactoryBase(_sourceURI, _compilerVersion, _compilerFlags) {
        stateless = true;
    }
}


contract StatefulFactory is FactoryBase {
    function StatefulFactory(string _sourceURI, string _compilerVersion, string _compilerFlags)
             FactoryBase(_sourceURI, _compilerVersion, _compilerFlags) {
        stateless = false;
    }
}
