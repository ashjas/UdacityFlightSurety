
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var Web3 = require("web3")
contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  it(`First airline queued`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isAirlineQueued.call(config.owner);
    assert.equal(status, "AirIndia", "first airline queued.");

  });
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
      var res1 = false, res2 = false;
      try 
      {
        await config.flightSuretyData.setOperatingStatus(true, { from: config.owner });//ensure its operational.
        res1 = await config.flightSuretyData.isOperational.call();//res1 should be true;
        await config.flightSuretyData.setOperatingStatus(false, { from: accounts[2] });// this should raise exception for !owner.
        res2 = await config.flightSuretyData.isOperational.call();
        //assert.notEqual(res1,res2,"Operation changed!");
        res2 = await config.flightSuretyData.setOperatingStatus(true, { from: config.owner });//ensure to make operational again.
      }
       catch(e) {
           assert.notEqual(res1,res2,"Access restricted to App Contract Owner!");
       }
       //assert.notEqual(res1,res2,"No Exception... Access restricted to App Contract Owner!");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, {from: config.owner});
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSuretyData.getAirlineCount.call(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline("AirIndia2",newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) Fund the first airline.', async () => {
    
    // ARRANGE

    // ACT
    try {
        await config.flightSuretyData.fund({from: config.owner,value: Web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      assert.equal(false,true,e.message);
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(config.owner); 

    // ASSERT
    assert.equal(result, true, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  // it('(airline) Second airline can be Queued by already registered Airline.', async () => {
    
  //   // ARRANGE
  //   let secondAirline = accounts[1];

  //   // ACT
  //   try {
  //     await config.flightSuretyApp.registerAirline("AirIndia2",secondAirline, {from: config.owner});
  //   }
  //   catch(e) {
  //     assert.equal(false,true,"Second airline cant register itself.");
  //   }
  //   let result = await config.flightSuretyData.isAirlineQueued.call(secondAirline); 

  //   // ASSERT
  //   assert.equal("AirIndia2", result, "2nd Airline Queued by the owner.");

  // });

  it('(airline) Register & Fund the 2nd,3rd,4th airlines', async () => {
    
     // ARRANGE
     let airline2 = accounts[1];
     let airline3 = accounts[2];
     let airline4 = accounts[3];

     // ACT
     try {
          //register and fund 2nd
          await config.flightSuretyApp.registerAirline("AirIndia2",airline2, {from: config.owner});
          await config.flightSuretyData.fund({from: airline2,value: Web3.utils.toWei('10', 'ether')});
          //register and fund 3rd
          await config.flightSuretyApp.registerAirline("AirIndia3",airline3, {from: airline2});
          await config.flightSuretyData.fund({from: airline3,value: Web3.utils.toWei('10', 'ether')});
          //register and fund 4th
          await config.flightSuretyApp.registerAirline("AirIndia4",airline4, {from: airline3});
          await config.flightSuretyData.fund({from: airline4,value: Web3.utils.toWei('10', 'ether')});
     }
     catch(e) {
       assert.equal(false,true,e.message);
     }
     let result = await config.flightSuretyData.isAirlineRegistered.call(airline2); 
     assert.equal(result, true, "Airline2 should be able to register.");
     
     result = await config.flightSuretyData.isAirlineRegistered.call(airline3); 
     assert.equal(result, true, "Airline3 should be able to register.");

     result = await config.flightSuretyData.isAirlineRegistered.call(airline4); 
     assert.equal(result, true, "Airline4 should be able to register.");
  });

  it('(airline) Register & Fund the 5th airline without consensus', async () => {
    
    // ARRANGE
    let airline4 = accounts[3];
    let airline5 = accounts[4];

    // ACT
    try {
         //register and fund 5th.. should error out..
         await config.flightSuretyApp.registerAirline("AirIndia5",airline5, {from: airline4});
         await config.flightSuretyData.fund({from: airline5,value: Web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      //assert.equal(false,true,e.message);
    }
    assert.equal(false,true,"5th Airline registered by existing airlines!");
 });
 

});
