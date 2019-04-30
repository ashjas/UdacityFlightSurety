pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    address private appContractOwner;
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint256 private REQUIRED_CONSENSUS_M = 4;//defaults to 4
    struct Airline 
    {
        string name;
        uint256 funds;
        bool isFunded;
    }
    
    struct Flight
    {
        address airline;
        string flight;
        uint256 timestamp;
        bool isRegistered;
        uint8 statusCode;
    }
    mapping(address => bool) private authorized;
    mapping(address => bytes32) private registeredFlight;//user to registered flight key mapping
    mapping(bytes32 => Flight) private flights;// flights operating in the system.
    mapping(string => address) private flightName2AirlineAddress;
    mapping(address => Airline) private registeredAirlines;
    mapping(bytes32 => uint256) public airlineVotes;// hash of name+airline+msg.sender => for tracking who already voted.
    mapping(bytes32 => uint256) public airlineVotesCount;// hash of name+airline => for vote Counting

    struct InsuredFlightCustomer
    {
        address customer;
        uint256 insuranceAmount;
    }
    struct InsuredFlightCustomers
    {
        InsuredFlightCustomer[] flightCustomers;// index is derived from hash of InsuredCustomerIndexHash[customerAddress+flightName+timestamp] => index.
        bool markRefund;
    }
    struct InsuredFlights
    {
        InsuredFlightCustomers[] insuredFlightDetails;// index is derived from hash of InsuredFlightIndexHash[flightName+timestamp] => index.
    }    
    mapping(address => InsuredFlights) private insuredLedger;// hash of airline address to mapping of insureeFunds.

    uint256 insuredFlightCounter = 0;
    uint256 insuredFlightCustomerCounter = 0;
    mapping(bytes32 => uint256) private InsuredFlightIndexHash;// needs to be updated when new flight is inserted.
    mapping(bytes32 => uint256) private InsuredCustomerIndexHash;// needs to be update when new customer is added.
    //address airline; address flightAddress; address customerAddress;uint256 timestamp;string flightName;
    //InsuredFlights insuredFlights = insuredLedger[airline];
    // uint256 flightIdx = InsuredFlightIndexHash[keccak256(abi.encodePacked(flightName,timestamp))];
    // uint256 customerIdx = InsuredCustomerIndexHash[keccak256(abi.encodePacked(customerAddress,flightName,timestamp))];
    // address customer = insuredFlights.insuredFlightDetails[flightIdx].flightCustomers[customerIdx].customer;
    // uint256 customerInsuranceAmount = insuredFlights.insuredFlightDetails[flightIdx].flightCustomers[customerIdx].insuranceAmount;
    function addInsuredCustomer(address airline, string flightName,uint256 timestamp, address customerAddress, uint256 payAmount ) external payable requireIsOperational()
    {
        // update the indexHashes..
        InsuredFlightIndexHash[keccak256(abi.encodePacked(flightName,timestamp))] = insuredFlightCounter++;
        InsuredCustomerIndexHash[keccak256(abi.encodePacked(customerAddress,flightName,timestamp))] = insuredFlightCustomerCounter++;
        InsuredFlightCustomer memory ifc = InsuredFlightCustomer({    
            customer : customerAddress,
            insuranceAmount: payAmount
        });
        contractOwner.transfer(payAmount);
        insuredLedger[airline].insuredFlightDetails[insuredFlightCounter - 1].flightCustomers[insuredFlightCustomerCounter - 1] = ifc;
        insuredLedger[airline].insuredFlightDetails[insuredFlightCounter - 1].markRefund = false;//set this to indicate, no refund has been initiated yet.
    }
    
    uint256 private constant init_fund_price = 1 ether;
    uint256 public airlineCount = 0;// count of airlines that are registered and funded.
    address[] public initialAirlines = new address[](0);

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the funding amount is sufficient, also checks if airline can take part in transactions.
    */
    modifier requireEnoughFunding()
    {
        if(registeredAirlines[msg.sender].isFunded)
        {
            _;
        }
        else
        {
            require(msg.value >= init_fund_price, "Initial funding not sufficient.");
            _;
        }
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function isAirlineRegistered(address airline) public view returns (bool)
    {
        if(registeredAirlines[airline].isFunded)
            return true;
        return false;
    }
    function isAirlineQueued(address airline) public view returns (string)
    {
        //if(registeredAirlines[airline].name == "AirIndia")
          //  return true;
        //return false;
        return registeredAirlines[airline].name;
    }
    function setAppContractOwner(address appAddress) public
    {
        appContractOwner = appAddress;
    }
    function authorizeCaller(address caller) public
    {
        authorized[caller] = true;
    }

    function isAuthorized(address caller) public view returns (bool)
    {
        return authorized[caller];
    }

    function getInitialAirlines(uint256 i) requireIsOperational() external view returns (address)
    {
        return initialAirlines[i];
    }

    function getAirlineCount() requireIsOperational() external view returns (uint256)
    {
        return airlineCount;
    }

    function getAirlineVotes(bytes32 key) requireIsOperational() external view returns (uint256)
    {
        return airlineVotes[key];
    }

    function setAirlineVotes(bytes32 key) requireIsOperational() external
    {
        airlineVotes[key] = 1;
    }

    function getAirlineVotesCount(bytes32 key) requireIsOperational() external view returns (uint256)
    {
        return airlineVotesCount[key];
    }

    function setAirlineVotesCount(bytes32 key) requireIsOperational() external
    {
        airlineVotesCount[key] = airlineVotesCount[key] + 1;
    }

    function getRegisteredFlight(address user) requireIsOperational() external view returns (bytes32)
    {
        return registeredFlight[user];
    }

    function getFlight(string flight, address airline, uint256 timestamp) requireIsOperational() external view returns (Flight)
    {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, timestamp));
        return flights[key];
    }
    
    // this function registers a flight in the data contract.
    function registerFlight(string airlineName,string flight, uint256 time) requireIsOperational() external
    {
        bytes32 key = keccak256(abi.encodePacked(flightName2AirlineAddress[airlineName], flight, time));//TODO: flightName2Airline is actually airlineName2AirlineAddress.
        require(flights[key].isRegistered == false,"Flight already registered.");
        flights[key] = Flight({
                                        isRegistered: true,
                                        statusCode: 0,//STATUS_CODE_UNKNOWN
                                        flight: flight,
                                        timestamp: time,
                                        airline: flightName2AirlineAddress[airlineName]
                                    });        
    }

    function processFlightStatus
                                (
                                    address airline,
                                    string flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                requireIsOperational()
                                external
    {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, timestamp));
        flights[key].statusCode = statusCode;
    }

    function setConsensus_M(uint256 m) external requireIsOperational()
    {
        REQUIRED_CONSENSUS_M = m;
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
    {
        require(msg.sender == appContractOwner);
        //require(operational != mode,"Operation mode requested already set.");
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                string name,
                                address airline
                            )
                            requireIsOperational()
                            external
    {
        registeredAirlines[airline].name = name;
        flightName2AirlineAddress[name] = airline;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (   string airlineName,
                                string flightName,
                                uint256 timestamp,
                                address customerAddress,
                                uint256 payAmount
                            )
                            requireIsOperational()
                            external
                            payable
    {
        bytes32 key = keccak256(abi.encodePacked(flightName2AirlineAddress[airlineName], flightName, timestamp));
        require(flights[key].isRegistered == true,"Flight not registered yet");
        this.addInsuredCustomer(flightName2AirlineAddress[airlineName],flightName,timestamp,customerAddress,payAmount);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address airline,
                                    string flightName,
                                    uint256 timestamp
                                )
                                requireIsOperational()
                                external
    {
        uint256 delayedFlightIdx = InsuredFlightIndexHash[keccak256(abi.encodePacked(flightName,timestamp))];
        insuredLedger[airline].insuredFlightDetails[delayedFlightIdx - 1].markRefund = true;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                string airlineName,
                                string flightName,
                                uint256 timestamp
                            )
                            requireIsOperational()
                            external payable
    {
        address customer = msg.sender;
        uint256 delayedFlightIdx = InsuredFlightIndexHash[keccak256(abi.encodePacked(flightName,timestamp))];
        uint256 customerIdx = InsuredCustomerIndexHash[keccak256(abi.encodePacked(customer,flightName,timestamp))];
        address airline = flightName2AirlineAddress[airlineName];
        if(insuredLedger[airline].insuredFlightDetails[delayedFlightIdx - 1].markRefund == true)
        {
            uint256 refundAmount = insuredLedger[airline].insuredFlightDetails[delayedFlightIdx - 1].flightCustomers[customerIdx - 1].insuranceAmount;
            refundAmount = refundAmount.mul(3).div(2);
            insuredLedger[airline].insuredFlightDetails[delayedFlightIdx - 1].flightCustomers[customerIdx - 1].insuranceAmount = 0;//remove the credit.
            customer.transfer(refundAmount);
        }
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund()
                  public
                  payable
                  requireIsOperational()
                  requireEnoughFunding()
    {
        uint256 val = msg.value;
        contractOwner.transfer(val);
        registeredAirlines[msg.sender].isFunded = true;
        registeredAirlines[msg.sender].funds = val;
        if(airlineCount < 4){
            initialAirlines.push(msg.sender);
        }

        airlineCount++;
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        requireIsOperational()
                        internal
                        view
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
                            requireIsOperational()
    {
        fund();
    }


}

