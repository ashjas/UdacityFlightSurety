var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "hood outer advance century enter marriage symbol acquire access cactus family rather";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 0
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
