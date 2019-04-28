
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
    "0xb5e3cdd926c313bcee53834b4f8538689da6c30f",
    "0x857c4e76174837b6feb808d1f2312b2b107a612b",
    "0x72a5f92962f22b5e6e6a6080e41b239b860b63ed",
    "0xeafdf62c97a04ede9e03e2732b28de8148115845",
    "0x6d86c9ef753e21b187e5502131316c2b066885ea",
    "0xf46387f406d63d5144e0b439c5234ae999f0a69c",
    "0xfc34d53ad7d9f465dba419ad9056e562e1f7b8a3",
    "0xd447a3edb317435e45edadb0d1da1ecf2b437998",
    "0x29889c5b1fa71605d2f92783ddff201686c4b89b",
    "0xe9ce65546c1d0728f1f0ca5f80f0eef4f28dca9f"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    //console.log("flightsuretyData: " + flightSuretyData);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};