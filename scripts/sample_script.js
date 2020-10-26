const bre = require('@nomiclabs/buidler')

async function main() {
  // await bre.run('compile')
  const greeter = await ethers.getContractAt('Greeter', '0x23Cb275d07c1E323c151A9a56E6E5a1091ac0192')
  console.log(greeter.functions)
  const asdf = await greeter.functions.greet()

  console.log('got', asdf)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
