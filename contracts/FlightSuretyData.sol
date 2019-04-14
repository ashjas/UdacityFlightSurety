pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
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

    mapping(address => bytes32) private registeredFlight;//user to registered flight key mapping
    mapping(bytes32 => Flight) private flights;// flights operating in the system.
    mapping(string => address) private airlineNameToAddress;
    mapping(address => Airline) private registeredAirlines;
    uint256 public airlineCount = 0;// count of airlines that are registered and funded.
    address[] public initialAirlines = new address[](0);
    mapping(bytes32 => uint256) public airlineVotes;// hash of name+airline+msg.sender => for tracking who already voted.
    mapping(bytes32 => uint256) public airlineVotesCount;// hash of name+airline => for vote Counting
    uint256 private constant init_fund_price = 10 ether;

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
    function getInitialAirlines(uint256 i) external returns (address)
    {
        return initialAirlines[i];
    }

    function getAirlineCount() external returns (uint256)
    {
        return airlineCount;
    }

    function getAirlineVotes(bytes32 key) external returns (uint256)
    {
        return airlineVotes[key];
    }

    function setAirlineVotes(bytes32 key) external
    {
        airlineVotes[key] = 1;
    }

    function getAirlineVotesCount(bytes32 key) external returns (uint256)
    {
        return airlineVotesCount[key];
    }

    function setAirlineVotesCount(bytes32 key) external
    {
        airlineVotesCount[key] += 1;
    }

    function getRegisteredFlight(address user) external returns (bytes32)
    {
        return registeredFlight[user];
    }

    function getFlight(string flight, address airline, uint256 timestamp) external returns (Flight)
    {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, timestamp));
        return flights[key];
    }
    
    function registerFlight(string flight, uint256 time) external
    {
        require(flights[registeredFlight[msg.sender]].isRegistered == true,"Flight already registered for caller.");
        bytes32 key = keccak256(abi.encodePacked(airlineNameToAddress[flight], flight, time));
        flights[key] = Flight({
                                        isRegistered: true,
                                        statusCode: 0,//STATUS_CODE_UNKNOWN
                                        flight: flight,
                                        timestamp: time,
                                        airline: airlineNameToAddress[flight]
                                    });
        registeredFlight[msg.sender] = key;
        
    }

    function processFlightStatus
                                (
                                    address airline,
                                    string flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
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
                            external
                            requireIsOperational()
    {
        registeredAirlines[airline].name = name;
        airlineNameToAddress[name] = airline;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
                            requireIsOperational()
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                requireIsOperational()
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            requireIsOperational()
    {
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
                        pure
                        internal
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

