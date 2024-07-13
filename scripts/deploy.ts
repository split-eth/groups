import { ethers } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying contracts with the account:', deployer.address);

    const GroupFactory = await ethers.getContractFactory('GroupFactory');
    const groupFactory = await GroupFactory.deploy(deployer.address, {
        gasLimit: 3000000,
    });

    console.log('GroupFactory deployed to:', groupFactory.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
