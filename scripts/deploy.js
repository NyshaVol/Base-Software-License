const hre = require("hardhat");
async function main() {
  const Hub = await hre.ethers.getContractFactory("AuraSoftwareLicenseHub");
  const hub = await Hub.deploy();
  await hub.deployed();
  console.log("License Hub deployed to:", hub.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
