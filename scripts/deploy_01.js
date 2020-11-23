const bre = require('@nomiclabs/buidler')
const { ethers, upgrades } = bre

async function main() {
    await bre.run('compile')

    const BaseToken = await ethers.getContractFactory('BaseToken')
    const baseToken = await upgrades.deployProxy(BaseToken, [])
    await baseToken.deployed()
    console.log('BaseToken deployed to:', baseToken.address)

    const BaseTokenMonetaryPolicy = await ethers.getContractFactory('BaseTokenMonetaryPolicy')
    const baseTokenMonetaryPolicy = await upgrades.deployProxy(BaseTokenMonetaryPolicy, [baseToken.address, '483703019126'])
    await baseTokenMonetaryPolicy.deployed()
    console.log('BaseTokenMonetaryPolicy deployed to:', baseTokenMonetaryPolicy.address)

    const BaseTokenOrchestrator = await ethers.getContractFactory('BaseTokenOrchestrator')
    const baseTokenOrchestrator = await upgrades.deployProxy(BaseTokenOrchestrator, [baseTokenMonetaryPolicy.address])
    await baseTokenOrchestrator.deployed()
    console.log('BaseTokenOrchestrator deployed to:', baseTokenOrchestrator.address)

    await (await baseToken.setMonetaryPolicy(baseTokenMonetaryPolicy.address)).wait()
    await (await baseTokenMonetaryPolicy.setOrchestrator(baseTokenOrchestrator.address)).wait()
    await (await baseTokenMonetaryPolicy.setMcapOracle('0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2')).wait()
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
