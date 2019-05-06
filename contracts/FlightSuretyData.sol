pragma solidity ^0.4.24;

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
    uint256 private REQUIRED_CONSENSUS_PERCENT = 2;
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
    mapping(string => address) private airlineName2AirlineAddress;
    mapping(address => Airline) private registeredAirlines;
    mapping(bytes32 => uint256) public airlineVotes;// hash of name+airline+msg.sender => for tracking who already voted.
    mapping(bytes32 => uint256) public airlineVotesCount;// hash of name+airline => for vote Counting

     struct FlightInsuredCustomers
    {
        address customer;
        uint256 insuranceAmount;
        uint256 refundAmount;
    }
    struct AirlineInsuredFlights
    {
        mapping(bytes32 => FlightInsuredCustomers) flightInsuredCustomers;
        bool markRefund;
    }
    struct AllInsuredFlights
    {
        mapping(bytes32 => AirlineInsuredFlights) airlineInsuredFlights;
    }
    mapping(address => FlightInsuredCustomers) insureeList;
    mapping(address => AllInsuredFlights) private insuredLedger;// hash of airline address to mapping of insureeFunds.

    function addInsuredCustomer(address airline, string flightName,uint256 timestamp, address customerAddress)
                                external
                                payable
                                requireIsOperational()
    {
        //check for customer already insured..
        bytes32 airlineInsuredFlightsIdx = keccak256(abi.encodePacked(flightName,timestamp));
        bytes32 flightInsuredCustomersIdx = keccak256(abi.encodePacked(customerAddress,flightName,timestamp));
        FlightInsuredCustomers storage ifc = insuredLedger[airline].airlineInsuredFlights[airlineInsuredFlightsIdx].flightInsuredCustomers[flightInsuredCustomersIdx];
        require(ifc.customer != customerAddress,"One customer can purchase a single insurance only.");
        
        //Add new insured customer.
        uint256 payAmount = msg.value;
        FlightInsuredCustomers memory ifc1 = FlightInsuredCustomers({
            customer : customerAddress,
            insuranceAmount: payAmount,
            refundAmount : 0
        });
        contractOwner.transfer(payAmount);
        insuredLedger[airline].airlineInsuredFlights[airlineInsuredFlightsIdx].flightInsuredCustomers[flightInsuredCustomersIdx] = ifc1;
        insuredLedger[airline].airlineInsuredFlights[airlineInsuredFlightsIdx].markRefund = false;
        insureeList[customerAddress] = ifc1;
    }
    
    uint256 private constant init_fund_price = 10 ether;
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
        return registeredAirlines[airline].isFunded;
    }
    function getAirlineNameByAddress(address airline) public view returns (string)
    {
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

    function getAirlineAddressByName(string name) public view returns (address)
    {
        return airlineName2AirlineAddress[name];
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

    function isFlightRegistered(string flight, string airlineName, uint256 timestamp) requireIsOperational() external view returns (bool)
    {
        bytes32 key = keccak256(abi.encodePacked(airlineName2AirlineAddress[airlineName], flight, timestamp));
        return flights[key].isRegistered;
    }

    // this function registers a flight in the data contract.
    function registerFlight(string airlineName,string flight, uint256 time) requireIsOperational() external
    {
        bytes32 key = keccak256(abi.encodePacked(airlineName2AirlineAddress[airlineName], flight, time));//TODO: flightName2Airline is actually airlineName2AirlineAddress.
        //require(flights[key].isRegistered == false,"Flight already registered.");
        flights[key] = Flight({
                                        isRegistered: true,
                                        statusCode: 0,//STATUS_CODE_UNKNOWN
                                        flight: flight,
                                        timestamp: time,
                                        airline: airlineName2AirlineAddress[airlineName]
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

    function setConsensus_Perc(uint256 p) external requireIsOperational()
    {
        REQUIRED_CONSENSUS_M = p;
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
        require(msg.sender == appContractOwner,"Modifying Operation mode requires owner.");
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
        airlineName2AirlineAddress[name] = airline;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (   string airlineName,
                                string flightName,
                                uint256 timestamp,
                                address passenger
                            )
                            requireIsOperational()
                            external
                            payable
    {
        bytes32 key = keccak256(abi.encodePacked(airlineName2AirlineAddress[airlineName], flightName, timestamp));
        require(flights[key].isRegistered == true,"Flight not registered yet");
        this.addInsuredCustomer.value(msg.value)(airlineName2AirlineAddress[airlineName],flightName,timestamp,passenger);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    string airlineName,
                                    string flightName,
                                    uint256 timestamp
                                )
                                requireIsOperational()
                                external
    {
        require(appContractOwner == msg.sender,"Caller not authorized");
        bytes32 delayedFlightIdx = keccak256(abi.encodePacked(flightName,timestamp));
        address airline = airlineName2AirlineAddress[airlineName];
        insuredLedger[airline].airlineInsuredFlights[delayedFlightIdx].markRefund = true;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                string airlineName,
                                string flightName,
                                uint256 timestamp,
                                address customer
                            )
                            requireIsOperational()
                            external payable
    {
        bytes32 delayedFlightIdx = keccak256(abi.encodePacked(flightName,timestamp));
        bytes32 customerIdx = keccak256(abi.encodePacked(customer,flightName,timestamp));
        address airline = airlineName2AirlineAddress[airlineName];
        if(insuredLedger[airline].airlineInsuredFlights[delayedFlightIdx].markRefund == true)
        {
            uint256 refundAmount = insuredLedger[airline].airlineInsuredFlights[delayedFlightIdx].flightInsuredCustomers[customerIdx].insuranceAmount;
            refundAmount = refundAmount.mul(3).div(2);
            insuredLedger[airline].airlineInsuredFlights[delayedFlightIdx].flightInsuredCustomers[customerIdx].insuranceAmount = 0;//remove the credit.
            customer.transfer(refundAmount);
        }
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund(address airline)
                  public
                  payable
                  requireIsOperational()
                  requireEnoughFunding()
    {
        uint256 val = msg.value;
        contractOwner.transfer(val);
        if(airline != address(0))
        {
            registeredAirlines[airline].isFunded = true;
            registeredAirlines[airline].funds = val;
            if(airlineCount < 4){
                initialAirlines.push(airline);
            }
            airlineCount++;
        }        
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
        fund(0);
    }


}

