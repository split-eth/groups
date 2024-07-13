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
    await groupFactory.initialize(owner.address);
  });

  describe("Functionality", function () {
    it("Should create a new Group contract", async function () {
      const groupName = "Test Group";
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes(groupName));

      await groupFactory.createGroup(groupName, addr1.address);

      const groupAddress = await groupFactory.groups(groupHash);
      expect(groupAddress).to.not.equal(ethers.constants.AddressZero);

      const group = await ethers.getContractAt("Group", groupAddress);
      expect(group).to.exist;

      const admin = await group.admin();
      expect(admin).to.equal(addr1.address);
    });

    it("Should revert if trying to create a group with an existing hash", async function () {
      const groupName = "Test Group";
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes(groupName));

      await groupFactory.createGroup(groupName, addr1.address);

      await expect(groupFactory.createGroup(groupName, addr2.address)).to.be.revertedWith("Group already exists");
    });

    
  });
});
