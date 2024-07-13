FactoryGroup.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./Group.sol";

contract GroupFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    Group public groupImplementation;
    mapping(bytes32 => address) public groups;

    event GroupCreated(address indexed groupAddress, bytes32 indexed groupHash);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address anOwner) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        transferOwnership(anOwner);

        groupImplementation = new Group();
    }

    function createGroup(address owner, bytes32 hash) external returns (Group ret) {
        address addr = getAddress(owner, hash);

        emit GroupCreated(addr, hash);

        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return Group(payable(addr));
        }
        ret = Group(
            payable(
                new ERC1967Proxy{salt: hash}(
                    address(groupImplementation),
                    abi.encodeWithSignature("initialize(address,address)", owner, address(this))
                )
            )
        );
    }

    function getAddress(address owner, bytes32 hash) public view returns (address) {
        return Create2.computeAddress(
            hash,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(groupImplementation),
                        abi.encodeWithSignature("initialize(address,address)", owner, address(this))
                    )
                )
            )
        );
    }

    function upgradeGroupImplementation(address newImplementation) external onlyOwner {
        groupImplementation = Group(newImplementation);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        (newImplementation);
    }
}
