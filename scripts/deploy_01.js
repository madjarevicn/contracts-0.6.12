const bre = require('@nomiclabs/buidler')
const { ethers, upgrades } = bre

async function main() {
    await bre.run('compile')

    const BaseToken = await ethers.getContractFactory('BaseToken')
    const baseToken = await upgrades.deployProxy(BaseToken, [])
    await baseToken.deployed()
    console.log('BaseToken deployed to:', baseToken.address)

    const BaseTokenMonetaryPolicy = await ethers.getContractFactory('BaseTokenMonetaryPolicy')
    const baseTokenMonetaryPolicy = await upgrades.deployProxy(BaseTokenMonetaryPolicy, [baseToken.address, '300000000'])
    await baseTokenMonetaryPolicy.deployed()
    console.log('BaseTokenMonetaryPolicy deployed to:', baseTokenMonetaryPolicy.address)

    const BaseTokenOrchestrator = await ethers.getContractFactory('BaseTokenOrchestrator')
    const baseTokenOrchestrator = await upgrades.deployProxy(BaseTokenOrchestrator, [baseTokenMonetaryPolicy.address])
    await baseTokenOrchestrator.deployed()
    console.log('BaseTokenOrchestrator deployed to:', baseTokenOrchestrator.address)
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
