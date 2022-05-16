// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

// approvers - ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]

contract Wallet {
    address[] approvers;
    uint256 public quorum;

    struct Transfer {
        uint256 id;
        uint256 amount;
        address payable to;
        uint256 approvals;
        bool sent;
    }

    Transfer[] transfers;
    mapping(address => mapping(uint256 => bool)) public approvals;

    constructor(address[] memory _approvers) {
        approvers = _approvers;
        quorum = (approvers.length + 1) / 2;
    }

    function getApprovers() external view returns (address[] memory) {
        return approvers;
    }

    function getTransfers() external view returns (Transfer[] memory) {
        return transfers;
    }

    function createTransfer(uint256 amount, address payable to)
        external
        onlyApprover
    {
        transfers.push(
            Transfer(transfers.length, amount * (10**18), to, 0, false)
        );
    }

    function approveTransfer(uint256 id) external onlyApprover {
        require(
            transfers[id].sent != true,
            "This transfer has already been sent!"
        );
        require(
            approvals[msg.sender][id] != true,
            "Cannot approve a single transfer twice"
        );

        approvals[msg.sender][id] = true;
        transfers[id].approvals++;

        if (transfers[id].approvals >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint256 amount = transfers[id].amount;
            to.call(abi.encode(amount));
        }
    }

    receive() external payable {}

    modifier onlyApprover() {
        bool allowed = false;

        for (uint256 i = 0; i < approvers.length; i++) {
            if (msg.sender == approvers[i]) {
                allowed = true;
                break;
            }
        }

        require(allowed == true, "Only approver allowed");
        _;
    }
}
