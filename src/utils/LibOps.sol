library LibOps {
  using LibOps for Operation;
  using LibOps for OperationBatch;

  struct Operation {
    address target;
    bytes32 config;
    uint256 value;
    bytes payload;
  }

  struct OperationBatch {
    Operation[] operations;
    uint256 deadline;
  }

  bytes32 internal constant _OPERATION_TYPEHASH = keccak256("Operation(address target,bytes32 config,uint256 value,bytes payload)");

  bytes32 internal constant _OPERATION_BATCH_TYPEHASH = keccak256(
    "OperationBatch(Operation[] operation,uint256 deadline)Operation(address target,bytes32 config,uint256 value,bytes payload)"
  );

  function hash(Operation calldata operation) internal pure returns (bytes32) {
    return keccak256(abi.encode(_OPERATION_TYPEHASH, operation.target, operation.config, keccak256(operation.payload)));
  }


  function hash(OperationBatch calldata payload) internal pure returns (bytes32) {
    Operation[] calldata ops = payload.operations;
    uint256 opsLength = ops.length;
    bytes32[] memory opsHashes = new bytes32[](opsLength);

    for (uint256 i = 0; i < opsLength; i++) {
      opsHashes[i] = hash(ops[i]);
    }

    return keccak256(
      abi.encode(
        _OPERATION_BATCH_TYPEHASH,
        keccak256(abi.encodePacked(opsHashes)),
        payload.deadline
      )
    );
  }
}
