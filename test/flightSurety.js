
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var Web3 = require("web3")
contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

//   var options = {
//     fromBlock: 0,
//     address: Web3.eth.defaultAccount,
//     topics: ["0x0000000000000000000000000000000000000000000000000000000000000000", null, null]
//     };
//     Web3.eth.subscribe('logs', options, function (error, result) {
//         if (!error)
//             console.log(result);
//     })
//         .on("data", function (log) {
//             console.log(log);
//         })
//         .on("changed", function (log) {
//     });
  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          var res1 = await config.flightSuretyData.isOperational.call();
          await config.flightSuretyData.setOperatingStatus(!res1, { from: owner });
          var res2 = await config.flightSuretyData.isOperational.call();
          console.log(res1,res2);
          assert.equal(true,false,"Operation changed!");
          assert;
          asdf
      }
      catch(e) {
          accessDenied = true;
      }
      //assert.equal(accessDenied, true, "Access restricted to App Contract Owner!");
            
  });

//   it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

//       // Ensure that access is allowed for Contract Owner account
//       let accessDenied = false;
//       try 
//       {
//           await config.flightSuretyData.setOperatingStatus(false);
//       }
//       catch(e) {
//           accessDenied = true;
//       }
//       assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
//   });

//   it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

//       await config.flightSuretyData.setOperatingStatus(false);

//       let reverted = false;
//       try 
//       {
//           await config.flightSurety.setTestingMode(true);
//       }
//       catch(e) {
//           reverted = true;
//       }
//       assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

//       // Set it back for other tests to work
//       await config.flightSuretyData.setOperatingStatus(true);

//   });

//   it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
//     // ARRANGE
//     let newAirline = accounts[2];

//     // ACT
//     try {
//         await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
//     }
//     catch(e) {

//     }
//     let result = await config.flightSuretyData.isAirline.call(newAirline); 

//     // ASSERT
//     assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

//   });
 

});
