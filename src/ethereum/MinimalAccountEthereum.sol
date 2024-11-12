//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccountEthereum is IAccount, Ownable {
    IEntryPoint private immutable i_entryPoint;

    error MinimalAccountEthereum__NotFromEntryPoint();
    error MinimalAccountEthereum__NotFromEntryPointOrOwner();
    error MinimalAccountEthereum__CallFailed(bytes);

    modifier fromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccountEthereum__NotFromEntryPoint();
        }
        _;
    }

    modifier fromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccountEthereum__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    //////////////////////////
    ////EXTERNAL FUNCTIONS////
    //////////////////////////
    function execute(address dest, uint256 value, bytes calldata data) external fromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(data);
        if (!success) {
            revert MinimalAccountEthereum__CallFailed(result);
        }
    }

    receive() external payable {}

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        fromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        //validate Nonce, if required, entryPoint takes care of it
        _payPrefund(missingAccountFunds);
    }

    //////////////////////////
    ////Internal Functions////
    //////////////////////////

    //EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            require(success, "failed to send prefund");
        }
    }

    ///////////////
    ////GETTERS////
    ///////////////

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
