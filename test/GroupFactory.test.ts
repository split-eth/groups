import { expect } from "chai";
import { ethers } from "hardhat";

describe("GroupFactory", function () {
  let GroupFactory: any;
  let Group: any;
  let groupFactory: any;
  let owner: any;
  let addr1: any;
  let addr2: any;
  let addrs: any;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    Group = await ethers.getContractFactory("Group");
    GroupFactory = await ethers.getContractFactory("GroupFactory");

    groupFactory = await GroupFactory.deploy();
    await groupFactory.deployed();
  });

  describe("Functionality", function () {
    it("Should create a new Group contract", async function () {
      const ownerAddress = await addr1.getAddress();
      const tokenAddress = ethers.constants.AddressZero;
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes("test-hash"));

      const tx = await groupFactory.createGroup(ownerAddress, tokenAddress, groupHash);
      await tx.wait();

      const groupAddress = await groupFactory.groups(groupHash);
      expect(groupAddress).to.not.equal(ethers.constants.AddressZero);

      const group = await ethers.getContractAt("Group", groupAddress);
      const admin = await group.admin();
      expect(admin).to.equal(ownerAddress);
    });

    it("Should revert if trying to create a group with an existing hash", async function () {
      const ownerAddress = await addr1.getAddress();
      const tokenAddress = ethers.constants.AddressZero;
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes("test-hash"));

      await groupFactory.createGroup(ownerAddress, tokenAddress, groupHash);
      await expect(groupFactory.createGroup(ownerAddress, tokenAddress, groupHash)).to.be.reverted;
    });

    it("Should return the correct address using Create2", async function () {
      const ownerAddress = await addr1.getAddress();
      const tokenAddress = ethers.constants.AddressZero;
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes("test-hash"));

      const computedAddress = await groupFactory.getAddress(ownerAddress, tokenAddress, groupHash);

      const salt = groupHash;
      const bytecode = ethers.solidityPack(
        ['bytes', 'bytes'],
        [
          (await ethers.getContractFactory('ERC1967Proxy')).bytecode,
          ethers.defaultAbiCoder.encode(
            ['address', 'bytes'],
            [await groupFactory.groupImplementation(), await groupFactory.groupImplementation().interface.encodeFunctionData('initialize', [ownerAddress, tokenAddress])]
          ),
        ]
      );

      const predictedAddress = ethers.getCreate2Address(groupFactory.address, salt, ethers.keccak256(bytecode));
      expect(computedAddress).to.equal(predictedAddress);
    });
  });

  describe("Events", function () {
    it("Should emit GroupCreated event on group creation", async function () {
      const ownerAddress = await addr1.getAddress
