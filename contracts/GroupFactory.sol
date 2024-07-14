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

    function getGroupHash(address token, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, salt));
    }

    function createGroup(address owner, address token, bytes32 salt, string memory name) external returns (Group ret) {
        address addr = getAddress(token, salt);

        bytes32 groupHash = getGroupHash(token, salt);

        emit GroupCreated(addr, groupHash);

        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return Group(payable(addr));
        }
        ret = Group(
            payable(
                new ERC1967Proxy{salt: groupHash}(
                    address(groupImplementation), abi.encodeCall(Group.initialize, (address(this), token))
                )
            )
        );

        ret.setGroupName(name);
        ret.transferOwnership(owner);
        ret.addUser(owner);
        ret.setAdmin(owner);
    }

    function getAddress(address token, bytes32 salt) public view returns (address) {
        return Create2.computeAddress(
            getGroupHash(token, salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(address(groupImplementation), abi.encodeCall(Group.initialize, (address(this), token)))
                )
            )
        );
    }
}
