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

    const groupFactory = await GroupFactory.deploy();
    const tx =  groupFactory.deploymentTransaction();
    await tx.wait();
  });
  
  describe("Functionality", function () {
    it("Should create a new Group contract", async function () {
      const ownerAddress = await addr1.getAddress();
      const tokenAddress = ethers.AddressZero;
      const groupHash = ethers.keccak256(ethers.toUtf8Bytes("test-hash"));

      const tx = await groupFactory.createGroup(ownerAddress, tokenAddress, groupHash);
      await tx.wait();

      const groupAddress = await groupFactory.groups(groupHash);
      expect(groupAddress).to.not.equal(ethers.AddressZero);

      const group = await ethers.getContractAt("Group", groupAddress);
      const admin = await group.admin();
      expect(admin).to.equal(ownerAddress);
    });
  
      it("Should revert if trying to create a group with an existing hash", async function () {
        const ownerAddress = await addr1.getAddress();
        const tokenAddress = ethers.AddressZero;
        const groupHash = ethers.keccak256(ethers.toUtf8Bytes("test-hash"));
  
        await groupFactory.createGroup(ownerAddress, tokenAddress, groupHash);
        await expect(groupFactory.createGroup(ownerAddress, tokenAddress, groupHash)).to.be.reverted;
      });
  
  });   
  
  
});
  
  


