// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

contract ChequeBank {
    struct ChequeInfo {
        uint amount;
        bytes32 chequeId;
        uint32 validFrom;
        uint32 validThru;
        address payable payee;
        address payable payer;
        address contractAddress;
    }
    struct SignOverInfo {
        uint8 counter;
        bytes32 chequeId;
        address oldPayee;
        address newPayee;
    }

    struct Cheque {
        ChequeInfo chequeInfo;
        bytes sig;
    }
    struct SignOver {
        SignOverInfo signOverInfo;
        bytes sig;
    }

    bytes32[] chequeIdLists;
    mapping(bytes32 => Cheque) chequeLists;

    address _owner;

    modifier byOwner() {
        require(msg.sender == _owner, "You are not the owner");

        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function deposit() external payable {}

    function withdraw(uint amount) external byOwner {
        require(amount >= getBalance(), "Your balance is low!");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed!");
    }

    function withdrawTo(uint amount, address payable recipient)
        external
        byOwner
    {
        require(amount >= getBalance(), "Your balance is low!");

        recipient.transfer(amount);
    }

    function redeem(Cheque memory chequeData) external {
        require(
            isChequeValid(
                chequeData.chequeInfo.payee,
                chequeData,
                chequeData.sig
            ),
            "Your message verification failed"
        );

        chequeData.chequeInfo.payee.transfer(chequeData.chequeInfo.amount);
    }

    function revoke(bytes32 chequeId) external byOwner {
        require(isExistChequeId(chequeId), "Cheque id is not exist!");

        Cheque memory chequeinfo = chequeLists[chequeId];

        if (
            block.timestamp > chequeinfo.chequeInfo.validFrom &&
            block.timestamp < chequeinfo.chequeInfo.validThru
        ) {
            delete chequeLists[chequeId];

            for (uint i = 0; i < chequeIdLists.length; i++) {
                if (chequeIdLists[i] == chequeId) {
                    delete chequeIdLists[i];
                }
            }
        }
    }

    function notifySignOver(SignOver memory signOverData) external {}

    function redeemSignOver(
        Cheque memory chequeData,
        SignOver[] memory signOverData
    ) external {}

    function isChequeValid(
        address payee,
        Cheque memory chequeData,
        bytes memory sig
    ) public pure returns (bool) {
        bytes32 messageHash = getChequeHash(chequeData);
        bytes32 ethSignedMessageHash = getEthSignedChequeHash(messageHash);

        return recoverSigner(ethSignedMessageHash, sig) == payee;
    }

    function getChequeHash(Cheque memory chequeData)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    chequeData.chequeInfo.chequeId,
                    chequeData.chequeInfo.payer,
                    chequeData.chequeInfo.payee,
                    chequeData.chequeInfo.amount,
                    chequeData.chequeInfo.contractAddress,
                    chequeData.chequeInfo.validFrom,
                    chequeData.chequeInfo.validThru
                )
            );
    }

    function getEthSignedChequeHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function isExistChequeId(bytes32 chequeId) private view returns (bool) {
        for (uint256 index = 0; index < chequeIdLists.length; index++) {
            if (chequeIdLists[index] == chequeId) {
                return true;
            }
        }

        return false;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}
