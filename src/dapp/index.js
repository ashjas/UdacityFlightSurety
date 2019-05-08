
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let res = null;

    let allFlights = [];

    function getFlightInfo(flightName) {
        for(let i = 0; i < allFlights.length; i++) {
            if(allFlights[i].flightName === flightName) {
                return allFlights[i];
            }
        }
        return null;
    }

    let contract = new Contract('localhost', () => {

        // Initialize flights
        allFlights = [
            {
                time: "15:15",
                timestamp: Math.floor(Date.now() / 1000),
                destination: "Delhi",
                flightName: "AIR005",
                airline: contract.owner,
                status: "0"
            },
            {
                time: "16:45",
                timestamp: Math.floor(Date.now() / 1000),
                destination: "Paris",
                flightName: "AIR006",
                airline: contract.owner,
                status: "0"
            },
            {
                time: "17:55",
                timestamp: Math.floor(Date.now() / 1000),
                destination: "Switzerland",
                flightName: "AIR007",
                airline: contract.owner,
                status: "0"
            }
        ];


        // Read transaction
        contract.isOperational((err, res) => {
            console.log(err,res);
            displayOperationalStatus([ { label: 'Operational Status', err: err, value: res} ]);
            displayFlightplan( allFlights, fetchFlightStatusCallback, registerFlightCallback);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (err, res) => {
                displaySubmitOracle('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', err: err, value: res.flight + ' ' + res.timestamp} ]);
            });
        })

        contract.getFlightInfo(res => {
            console.log("StatusInfo: " + JSON.stringify(res));
            let updateFlight = getFlightInfo(res.flight);
            if(updateFlight !== null) {
                updateFlight.status = res.status;
                let flight_row = DOM.elid("row_" + res.flight);
                displayUpdateFlightplanRow(flight_row, updateFlight, fetchFlightStatusCallback, registerFlightCallback);
            } else {
                console.log("Flight not found.");
            }
        });
    });
    function registerFlightCallback(flight, value){
        contract.registerFlight(getFlightInfo(flight), value, () => {
            console.log("Flight registered for insurance: " + JSON.stringify(flight));
        })
    }

    function fetchFlightStatusCallback(flight) {
        contract.fetchFlightStatus(getFlightInfo(flight), (err, res) => {
            if(err) {
                console.log(err);
            } else {
                console.log(res)
            }
        });
    }
})();

function displayFlightplan(flights, fetchFlightStatusCallback, registerFlightCallback) {
    let displayDiv = DOM.elid("display-wrapper");
    displayDiv.innerHTML = "";

    // Available Flights
    let sectionFlightPlan = DOM.section();
    sectionFlightPlan.appendChild(DOM.h2("Flightplan"));

    if(flights !== null){
        sectionFlightPlan.appendChild(DOM.h5("Available flights"));

        flights.map((flight) => {
            let row_id = 'row_' + flight.flightName;

            let row = sectionFlightPlan.appendChild(DOM.div({id: row_id, className:'row'}));
            displayUpdateFlightplanRow(row, flight, fetchFlightStatusCallback, registerFlightCallback);

            sectionFlightPlan.appendChild(row);
        })

    } else {
        sectionFlightPlan.appendChild(DOM.h5("Loading available Flights..."));
    }

    displayDiv.append(sectionFlightPlan);


}

function displayUpdateFlightplanRow(row, flight, fetchFlightStatusCallback, registerFlightCallback) {

    function resolveStatusText(status_id) {
        switch (status_id) {
            case "0":
                return "Unknown";

            case "10":
                return "On Time";

            case "20":
                return "Late Airline";

            case "30":
                return "Later Weather";

            case "40":
                return "Late Technical";

            case "50":
                return "Late Other";
        }

        return "not Available";
    }

    row.innerHTML = "";

    let dataElementId = flight.flightName + '_value';

    row.appendChild(DOM.div({className: 'col-sm-1 field-value', style: { margin: 'auto 0 auto 0'}}, flight.time));
    row.appendChild(DOM.div({className: 'col-sm-1 field-value', style: { margin: 'auto 0 auto 0'}}, flight.flightName));
    row.appendChild(DOM.div({className: 'col-sm-2 field-value', style: { margin: 'auto 0 auto 0'}}, flight.destination));
    row.appendChild(DOM.div({className: 'col-sm-2 field', style: { margin: 'auto 0 auto 0', color: flight.status === "20" ? '#FF0000' : '#FFFFFF'}}, resolveStatusText(flight.status)));

    let edtValue = DOM.input({id: dataElementId, className: 'field-value', style: { margin: 'auto 5px auto 30px', width: '40px', 'text-align': 'center'}, value: ''});
    row.appendChild(edtValue);

    row.appendChild(DOM.div({className: 'field-value', style: { margin: 'auto 0 auto 0', width: '40px'}}, "ETH"));

    let buttonInsuring = DOM.button({className: 'btn btn-warning', style: { margin: '5px'} }, "Buy insurance");
    buttonInsuring.addEventListener('click', () => {
        registerFlightCallback(flight.flightName, DOM.elid(dataElementId).value);
    });
    row.appendChild(buttonInsuring);
}

function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((res) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, res.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, res.err ? String(res.err) : String(res.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}

function displaySubmitOracle(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    console.log("displaySubmitOracle");
    // var x = document.getElementById(title);
    // if(x)
    // {
    //     document.removeChild(x);
    // }
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((res) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, res.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, res.err ? String(res.err) : String(res.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}
function displayOperationalStatus(status) {
    let displayDiv = DOM.elid("display-operational");
    displayDiv.innerHTML = "";

    let sectionOperationalStatus = DOM.section();
    sectionOperationalStatus.appendChild(DOM.h4('Operational Status'));
    sectionOperationalStatus.appendChild(DOM.h5('Check if contract is operational'));
    status.map((result) => {
        let row = sectionOperationalStatus.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        sectionOperationalStatus.appendChild(row);
    })
    displayDiv.append(sectionOperationalStatus);
}





