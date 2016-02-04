library MerkleLib {
    struct Tree {
        mapping (bytes32 => Node) nodes;
    }

    struct Node {
        bytes32 key;  // hash is a reserved word....
    }
}
