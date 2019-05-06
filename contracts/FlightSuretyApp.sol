pragma solidity ^0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    uint256 private constant REQUIRED_CONSENSUS_M = 4;
    uint256 private constant REQUIRED_CONSENSUS_PERCENT = 2;

    address private contractOwner;          // Account used to deploy contract
    FlightSuretyData flightSuretyData;
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

 
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
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");
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
    * @dev Modifier that requires that airline getting registered upto 4th is only registered by one of already registered airline.
    */
    modifier requireRegisterByExisting(string name,address airline)
    {
        bool success = false;
        if(flightSuretyData.getAirlineCount() < REQUIRED_CONSENSUS_M)
        {
            bool airlineExists = false;
            for(uint i = 0; i<3 ; ++i){
                if(flightSuretyData.getInitialAirlines(i) == msg.sender)
                {
                    airlineExists = true;
                    break;
                }
            }
            require(airlineExists,"Already registered and funded airlines can only register a new airline.");
            flightSuretyData.registerAirline(name,airline);
            success = true;
        }
        else
        {
            _;
        }
    }

    modifier requireConsensus(string name,address airline)
    {
        if(flightSuretyData.getAirlineCount() >= REQUIRED_CONSENSUS_M)
        {
            //address airline = flightSuretyData.getAirlineAddressByName(name);
            bytes32 voteCountHash = keccak256(abi.encodePacked(name,airline));
            uint256 votes = flightSuretyData.getAirlineVotesCount(voteCountHash);
            require(votes >= flightSuretyData.getAirlineCount().div(2),"Consensus of 50% Airline votes not met.");
        }
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                )
                                public
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
        flightSuretyData.setConsensus_M(REQUIRED_CONSENSUS_M);// pass on to reset/set the consensus number;
        flightSuretyData.setConsensus_Perc(REQUIRED_CONSENSUS_PERCENT);
        flightSuretyData.registerAirline("AirIndia1",msg.sender);
        flightSuretyData.setAppContractOwner(contractOwner);
    }

    function fund(string name,address airline) requireIsOperational() requireConsensus(name,airline) external payable
    {
        flightSuretyData.fund.value(msg.value)(airline);
    }
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
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
                            requireContractOwner()
                            internal
    {
        flightSuretyData.setOperatingStatus(mode);
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline
                            (
                                string name,
                                address airline,
                                address sender
                            )
                            requireIsOperational()
                            requireRegisterByExisting(name,airline)
                            public
                            //returns(bool success)
    {
        //code for multi party consensus.
        // if here, 4 airlines have already been registered.
        bytes32 airlineVotedKey = keccak256(abi.encodePacked(name,airline,sender));
        bytes32 voteCountHash = keccak256(abi.encodePacked(name,airline));
        bool duplicate = true;// this means, already voted address tried to registerAirline again.
        if(flightSuretyData.getAirlineVotes(airlineVotedKey) == 0)//this ensures same airline does not vote for another airline again.
        {
            flightSuretyData.setAirlineVotes(airlineVotedKey);
            flightSuretyData.setAirlineVotesCount(voteCountHash);
            duplicate = false;
        }
        require(!duplicate,"Duplicate votes for airline not allowed!");
        uint256 votes = flightSuretyData.getAirlineVotesCount(voteCountHash);
        //require(votes >= flightSuretyData.getAirlineCount().div(2) , "Consensus of 50% not achieved.");// This was a bug, revert here, reverses votes.
        if(votes >= flightSuretyData.getAirlineCount().div(2))
            flightSuretyData.registerAirline(name,airline);
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                    string airlineName,
                                    string flight,
                                    uint256 timestamp,
                                    address passenger
                                )
                                requireIsOperational()
                                payable
                                public
    {
        flightSuretyData.registerFlight(airlineName,flight,timestamp);
        this.buy.value(msg.value)(airlineName,flight,timestamp,passenger);
    }

    function buy(string airlineName,string flightName, uint256 timeStamp,address passenger) requireIsOperational() payable public
    {
        require(msg.value <= 1 ether,"Insurance purchase amount should be less than 1 ether.");
        flightSuretyData.buy.value(msg.value)(airlineName,flightName,timeStamp,passenger);
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flightName,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                requireIsOperational()
                                internal
    {
        flightSuretyData.processFlightStatus(airline,flightName,timestamp,statusCode);
        if(statusCode == STATUS_CODE_LATE_AIRLINE)
        {
            string memory airlineName = flightSuretyData.getAirlineNameByAddress(airline);//TODO why memory and not storage?
            flightSuretyData.creditInsurees(airlineName,flightName, timestamp);
        }
    }

    function withdrawOnDelay(string memory airlineName,string memory flightName,uint256 timestamp,address customer) requireIsOperational() public payable
    {
        flightSuretyData.pay(airlineName,flightName,timestamp,customer);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        requireIsOperational()
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
                            requireIsOperational()
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            external
                            view
                            requireIsOperational()
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
                        requireIsOperational()
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        requireIsOperational()
                        internal
                        view
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            requireIsOperational()
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            requireIsOperational()
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

contract FlightSuretyData{
    function getAirlineAddressByName(string name) public returns (address);
    function isOperational() public view returns(bool);
    function setOperatingStatus(bool mode) external;
    function registerAirline(string name,address airline) external;
    function setConsensus_M(uint256 m) external;
    function setConsensus_Perc(uint256 p) external;
    function getInitialAirlines(uint256 i) external returns (address);
    function getAirlineCount() external returns (uint256);
    function getAirlineVotes(bytes32 key) external returns (uint256);
    function getAirlineVotesCount(bytes32 key) external returns (uint256);
    function setAirlineVotes(bytes32 key) external;
    function setAirlineVotesCount(bytes32 key) external;
    function registerFlight(string airlineName,string flight, uint256 time) external;
    function processFlightStatus(address airline,string flight,uint256 timestamp,uint8 statusCode) external;
    function buy(string airlineName,string flightName,uint256 timestamp,address customer) external payable;
    function creditInsurees(string airlineName,string flightName,uint256 timestamp) external;
    function pay(string airlineName,string flightName,uint256 timestamp,address customer) external;
    function fund(address airline) public payable;
    function setAppContractOwner(address) public;
    function getAirlineNameByAddress(address airline) public view returns (string);
}
