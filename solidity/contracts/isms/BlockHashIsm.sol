// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";
import {PackageVersioned} from "contracts/PackageVersioned.sol";
import {Message} from "../libs/Message.sol";

interface IBlockHashOracle {
    function origin() external view returns (uint32);

    function blockHash(uint256 height) external view returns (uint256 hash);
}

/**
 * @notice Initializes the BlockHashISM contract with the provided oracle address.
 */
contract BlockHashISM is IInterchainSecurityModule, PackageVersioned {
    using Message for bytes;

    uint8 public constant override moduleType = uint8(Types.NULL);
    IBlockHashOracle public immutable oracle;

    constructor(address _oracle) {
        oracle = IBlockHashOracle(_oracle);
    }

    /**
     * @inheritdoc IInterchainSecurityModule
     * @notice Verifies whether a message was dispatched on the origin chain using a block hash oracle against the
     * block hash contained inside the message.
     * @dev The `message` parameter must be ABI-encoded with the `blockHash` (as `uint256`) and `blockHeight` (as `uint256`)
     * as the first two parameters, followed by any additional data.
     * @param message Message to verify.
     */
    function verify(
        bytes calldata,
        bytes calldata message
    ) public view override returns (bool) {
        (uint256 blockHash, uint256 blockHeight) = _extractBlockInfo(
            message.body()
        );

        // if the block hash at the specified height does not match the oracle results means the transaction was not mined on that origin chain
        require(
            oracle.blockHash(blockHeight) == blockHash,
            "Transaction not dispatched from origin chain"
        );

        return true;
    }

    /**
     * @notice Extracts the block hash and block height from the beginning of the message body.
     * @dev This function assumes that the first 64 bytes of `_messageBody` contain two `uint256` values:
     * `blockHash` and `blockHeight`. The function will revert if `_messageBody` is shorter than 64 bytes.
     * @param _messageBody The calldata containing the block information at its start.
     * @return hash The extracted block hash.
     * @return height The extracted block height.
     */
    function _extractBlockInfo(
        bytes calldata _messageBody
    ) internal view returns (uint256 hash, uint256 height) {
        require(_messageBody.length >= 64, "Invalid message body");

        (hash, height) = abi.decode(_messageBody[:64], (uint256, uint256));
    }
}
