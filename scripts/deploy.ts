import "@nomicfoundation/hardhat-toolbox";
import { ethers, run } from "hardhat";

async function main() {
  const GroupFactory = await ethers.getContractFactory("GroupFactory");
  const groupFactory = await GroupFactory.deploy();

  console.log(
    "GroupFactory deployed to:",
    await (groupFactory as any).getAddress()
  );

  const tx = groupFactory.deploymentTransaction();
  if (!tx) {
    throw new Error("Deployment transaction not found");
  }

  console.log("⏳ waiting to be confirmed...");
  tx.wait(5);

  console.log("🧐 verifying...\n");

  try {
    await run("verify:verify", {
      address: await (groupFactory as any).getAddress(),
      constructorArguments: [],
    });
  } catch (error: any) {
    console.log("Error verifying contract: %s\n", error && error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
