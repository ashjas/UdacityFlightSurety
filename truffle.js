var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "hood outer advance century enter marriage symbol acquire access cactus family rather";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 6721975
    },
    developmentOld: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 4500000,
      gasPrice: 10000
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
