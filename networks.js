require("dotenv/config")
const HDWalletProvider = require('@truffle/hdwallet-provider');
module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    kto: {
      provider: () => new HDWalletProvider(process.env.K_KEY, process.env.KTO_URL),
       network_id: 2559,
      skipDryRun: true,
      gas: 3000000,
      gasPrice: 100,
    },
    goerli: {
      provider: () => new HDWalletProvider(process.env.G_KEY, process.env.GOERLI_URL),
      network_id: 5,
      skipDryRun: true,
      gas: 5000000,
      gasPrice: 1000,
    },
  },
};


