// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./Group.sol";

contract GroupFactory {
    Group public groupImplementation;
    mapping(bytes32 => address) public groups;

    event GroupCreated(address indexed groupAddress, bytes32 indexed groupHash);

    constructor() {
        groupImplementation = new Group();
    }

    function createGroup(address owner, address token, bytes32 hash) external returns (Group ret) {
        address addr = getAddress(owner, token, hash);

        emit GroupCreated(addr, hash);

        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return Group(payable(addr));
        }
        ret = Group(
            payable(
                new ERC1967Proxy{salt: hash}(
                    address(groupImplementation), abi.encodeCall(Group.initialize, (owner, token))
                )
            )
        );
    }

    function getAddress(address owner, address token, bytes32 hash) public view returns (address) {
        return Create2.computeAddress(
            hash,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(address(groupImplementation), abi.encodeCall(Group.initialize, (owner, token)))
                )
            )
        );
    }
}
