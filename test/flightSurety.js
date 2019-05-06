
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var Web3 = require("web3");
contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  it(`First airline queued`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.getAirlineNameByAddress.call(config.owner);
    assert.equal(status, "AirIndia1", "first airline queued.");

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
        res2 = await config.flightSuretyData.setOperatingStatus(true, { from: config.owner });//ensure to make operational again.
      }
       catch(e) {
           assert.notEqual(res1,res2,"Access restricted to App Contract Owner!");
       }            
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
        await config.flightSuretyApp.registerAirline("AirIndia2",newAirline,newAirline.toString(),firstAirline.toString(), {from: config.firstAirline});
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
          await config.flightSuretyApp.fund("AirIndia1",config.owner,{from: config.owner,value: Web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      assert.equal(false,true,e.message);
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(config.owner); 
    // ASSERT
    assert.equal(result, true, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) Register & Fund the 2nd,3rd', async () => {
    
     // ARRANGE
     let airline2 = accounts[1];
     let airline3 = accounts[2];
     let airline4 = accounts[3];

     // ACT
     try {
          //register and fund 2nd
          await config.flightSuretyApp.registerAirline("AirIndia2",airline2,config.owner, {from: config.owner});
          await config.flightSuretyApp.fund("AirIndia2",airline2,{from: airline2,value: Web3.utils.toWei('10', 'ether')});
          //register and fund 3rd
          await config.flightSuretyApp.registerAirline("AirIndia3",airline3,config.owner, {from: config.owner});
          await config.flightSuretyApp.fund("AirIndia3",airline3,{from: airline3,value: Web3.utils.toWei('10', 'ether')});
     }
     catch(e) {
       assert.equal(false,true,e.message);
     }
     let result = await config.flightSuretyData.isAirlineRegistered.call(airline2); 
     assert.equal(result, true, "Airline2 should be able to register.");
     
     result = await config.flightSuretyData.isAirlineRegistered.call(airline3); 
     assert.equal(result, true, "Airline3 should be able to register.");
  });

  it('(airline) Register & Fund the 5th airline when existing registered and funded airline count is < 4', async () => {
    
    // ARRANGE
    let airline4 = accounts[3];
    let airline5 = accounts[4];
    let reverted = false;
    // ACT
    try {
         //register and fund 5th.. should error out..
         result = await config.flightSuretyApp.registerAirline("AirIndia5",airline5,airline4, {from: airline4});
         if(result)
          await config.flightSuretyApp.fund("AirIndia5",airline5,{from: airline5,value: Web3.utils.toWei('10', 'ether')});
    }
    catch(e) {
      reverted = true;
    }
    assert.equal(reverted,true,"5th Airline registered when existing registered and funded airline count is < 4!");
 });
 
 it('(airline) Register 4th airlines', async () => {
    
  // ARRANGE
  let airline3 = accounts[2];
  let airline4 = accounts[3];

  // ACT
  try {
       //register and fund 4th
       await config.flightSuretyApp.registerAirline("AirIndia4",airline4,airline3, {from: airline3});
       await config.flightSuretyApp.fund("AirIndia4",airline4,{from: airline4,value: Web3.utils.toWei('10', 'ether')});
  }
  catch(e) {
    assert.equal(false,true,e.message);
  }
  result = await config.flightSuretyData.isAirlineRegistered.call(airline4); 
  assert.equal(result, true, "Airline4 should be able to register.");
});

it('(airline) Register 5th airlines', async () => {
    
  // ARRANGE
  let airline3 = accounts[2];
  let airline4 = accounts[3];
  let airline5 = accounts[4];
// {
//   let airlineCount = await config.flightSuretyData.getAirlineCount.call();
//   console.log("Total AirlineCount:" + airlineCount);
//   let voteCountHash1 = await config.flightSuretyApp.getHash2("AirIndia5",airline5.toString());
//   console.log("voteCountHash1: " + voteCountHash1);
//   let airlineVotedKey3 = await config.flightSuretyApp.getHash3("AirIndia5",airline5.toString(),airline3.toString());
//   console.log("airlineVotedKey3: " + airlineVotedKey3);
//   let airlineVotedKey4 = await config.flightSuretyApp.getHash3("AirIndia5",airline5.toString(),airline4.toString());
//   console.log("airlineVotedKey4: " + airlineVotedKey4);
//   let voted3 = await config.flightSuretyData.getAirlineVotes.call(airlineVotedKey3);
//   let voted4 = await config.flightSuretyData.getAirlineVotes.call(airlineVotedKey4);
//   let voteCount = await config.flightSuretyData.getAirlineVotesCount.call(voteCountHash1);
//   console.log("airline3 Voted:?" + voted3);
//   console.log("airline4 Voted:?" + voted4);
//   console.log("airline5 VoteCount:" + voteCount);
// }
  // ACT
  let exceptionMessage = "";
  try {
       //register and fund 4th
       await config.flightSuretyApp.registerAirline("AirIndia5",airline5,airline3, {from: airline3});
       await config.flightSuretyApp.registerAirline("AirIndia5",airline5,airline4, {from: airline4});
       await config.flightSuretyApp.fund("AirIndia5",airline5,{from: airline5,value: Web3.utils.toWei('10', 'ether')});
  }
  catch(e) {
    exceptionMessage = e.message;
    //assert.equal(false,true,e.message);
  }
  let result = await config.flightSuretyData.isAirlineRegistered.call(airline5); 
  assert.equal(result, true, "Airline5 should be able to register.\n" + exceptionMessage);
  
  // //debug..
  // let airlineCount = await config.flightSuretyData.getAirlineCount.call();
  // for(i=airlineCount; i < airlineCount ; ++i)
  // {
  //   let airlineName = await config.flightSuretyData.getAirlineAddressByName.call("");
  //   console.log
  // }
});

it('(airline) Duplicate voting is not allowed.', async () => {
    
  // ARRANGE
  let airline5 = accounts[4];
  let airline6 = accounts[5];

  // ACT
  try {
       //register and fund 4th
       await config.flightSuretyApp.registerAirline("AirIndia6",airline6,airline5, {from: airline5});// first vote by airline5
       await config.flightSuretyApp.registerAirline("AirIndia6",airline6,airline5, {from: airline5});// second vote by airline5
  }
  catch(e) {
    //assert.equal(false,true,e.message);
  }
  result = await config.flightSuretyData.isAirlineRegistered.call(airline6); 
  assert.equal(result, false, "Airline6 was registered through duplicate voting!");
});

it('(insurance) Buy Insurance', async () => {
    
  // ARRANGE
  let passenger = accounts[6];
  let airlineName = "AirIndia1";
  let timestamp = 0;
  let flight = "AIR007";
  let insuredAmount = Web3.utils.toWei("0.9","ether");

  // ACT
  try {
       //registerFlight
       await config.flightSuretyApp.registerFlight(airlineName,flight,timestamp,passenger,{from:passenger,value:insuredAmount});
  }
  catch(e) {
    assert.equal(false,true,e.message);
  }
  result = await config.flightSuretyData.isFlightRegistered.call(flight,airlineName,timestamp);
  assert.equal(result,true, "Flight was Not registered!");
});

it('(insurance) Buy Insurance for a flight more than once.', async () => {
    
  // ARRANGE
  let passenger = accounts[6];
  let airlineName = "AirIndia1";
  let timestamp = 0;
  let flight = "AIR007";
  let insuredAmount = Web3.utils.toWei("0.9","ether");
  let reverted = false;
  // ACT
  try {
       //registerFlight
       await config.flightSuretyApp.registerFlight(airlineName,flight,timestamp,passenger,{from:passenger,value:insuredAmount});
  }
  catch(e) {
    //assert.equal(false,true,e.message);
    reverted = true;
  }
  assert.equal(reverted,true, "Flight was registered and insured more than once!");
});

it('(insurance) Credit customer of refund amount', async () => {
    
  // ARRANGE
  let passenger = accounts[6];
  let airlineName = "AirIndia6";
  let timestamp = 0;
  let flight = "AIR007";
  let reverted = false;
  // ACT
  try {
       //registerFlight
       await config.flightSuretyData.creditInsurees(airlineName,flight,timestamp,{from:config.owner});
       await config.flightSuretyApp.withdrawOnDelay(airlineName,flight,timestamp,passenger);
  }
  catch(e) {
    assert.equal(false,true,e.message);
    reverted = true;
  }
  assert.equal(reverted,false, "Credit to customer failed!");
});

});
