pragma solidity ^0.4.24;

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
    mapping(address => Airline) private registeredAirlines;
    uint256 public airlineCount = 0;// count of airlines that are registered and funded.
    address[] public initialAirlines = new address[](0);
    mapping(bytes32 => uint256) public airlineVotes;// hash of name+airline+msg.sender => for tracking who already voted.
    mapping(bytes32 => uint256) public airlineVotesCount;// hash of name+airline => for vote Counting

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
    * @dev Modifier that requires the funding amount is sufficient.
    */
    modifier requireEnoughFunding()
    {
        require(msg.value >= 1 ether, "Funding should be greater than 1 Ether");
        _;
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

    function setConsensus_M(uint256 m) external
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
                            requireEnoughFunding()
    {
        registeredAirlines[airline].name = name;
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
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
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
                            pure
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
    {
        fund();
    }


}

