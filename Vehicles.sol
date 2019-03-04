pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Vehicles{


    struct Car {
        uint id;
        string name;
        string vastidor;
		uint year;
        string others;  // additional conditions
        uint numberofupdates;
		string actualversion;
        uint [] updateStory; // times it has been updated and versioning
        uint [] activeStory; // changes between active and non active
        address owner; // who owns the car 
		bool active;
       // string hashIPFS; // hash of the elements of the struct, for auditing 
    }
    // key is a uint, later corresponding to the car id
    // what we store (the value) is a Car
    // the information of this mapping is the set of cars available in this SC.
    mapping(uint => Car) private cars; // 


	struct Story {
        uint id;
        uint id_car;
        string version;
        string timestamp;
        address maker; // who updates
    }

    mapping(uint => Story) private storiesChanges; //
	
	
	struct Status {
        uint id;
        uint id_car;
        bool actualstate;
        string timestamp;
        address maker; // who updates
    }

    mapping(uint => Status) private statusChanges; //

    
    struct FailedAttempt {
        uint id;
        uint id_car;
        string functioncall;
        string timestamp;
        address maker; // who updates
    }

    mapping(uint => FailedAttempt) private failedattempts; //


    uint private carsCount;
    uint private statusCount;
    uint private storyCount;
    uint private failedCount;


    // events, since SC is for global accounts it does not have too much sense but is left here 
    event updateEvent ( // triggers update complete
    );
	
	event changeStatusEvent ( // triggers status change
    );

    address constant public admin = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9; // who registers the car into system. 
	address constant public exampleowner = 0xE0F5206bbd039e7b0592d8918820024E2A743222;

    constructor () public { // constructor, inserts new car in system. we map starting from id=1, hardcoded values of all
        addCar("Toyota X","ADDeFFtt45045594xxE3948",2019, "other info","V.0.56771B",exampleowner); //
		
        changeStatusCar(1, true, "some timestamp");
        //updateCar(1, "V.0.6111A", "some timestamp");
        // try addstory and add status.
    }

	
	function addCar (string memory _name, string memory _vastidor, uint _year, string memory _others, string memory _actualversion, address _owner) public {
        //require(msg.sender==admin);

        carsCount ++; // inc count at the beginning. represents ID also. 
        cars[carsCount].id = carsCount; 
        cars[carsCount].name = _name;
        cars[carsCount].vastidor = _vastidor;
		cars[carsCount].year = _year;
        cars[carsCount].others = _others;
        cars[carsCount].numberofupdates = 0;
        cars[carsCount].actualversion = _actualversion;		
        cars[carsCount].owner = _owner;
        cars[carsCount].active = false;
        //cars[carsCount].hashIPFS = keccak256(abi.encodePacked(block.number,msg.data, cars[carsCount].id, cars[carsCount].name, cars[carsCount].vastidor, cars[carsCount].numberofupdates, cars[carsCount].actualversion, cars[carsCount].owner));
    }
	
	
	// update version of car, update hash
	function updateCar (uint _carId, string memory _actualversion, string memory _timestamp) public {
        require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks

        // store error calls possible malicious. also this spends gas
        if(msg.sender != cars[_carId].owner) {
            failedCount++;
            failedattempts[failedCount] = FailedAttempt(failedCount, _carId, "update",_timestamp, msg.sender); // we store error
        }


		require(msg.sender==cars[_carId].owner); // only owner
		require(true==cars[_carId].active); //  only if active
        

		storyCount++;
		
        storiesChanges[storyCount] = Story(storyCount, _carId, _actualversion,_timestamp, msg.sender); // the global struct
        cars[_carId].updateStory.push(storyCount); // we store the story reference in the corresponding car
		
		// now we update the local register, to have fast access
		cars[_carId].actualversion = _actualversion;
        // update hash
		//cars[carsCount].hashIPFS = keccak256(abi.encodePacked(block.number,msg.data, cars[carsCount].id, cars[carsCount].name, cars[carsCount].vastidor, cars[carsCount].numberofupdates,  cars[_carId].actualversion, cars[carsCount].owner));

        emit updateEvent(); // trigger event 
    }
	
	function changeStatusCar (uint _carId, bool _active, string memory _timestamp) public { 
        /*require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks


        // store error calls possible malicious
        if(msg.sender != cars[_carId].owner) {
            failedCount++;
            failedattempts[failedCount] = FailedAttempt(failedCount, _carId, "status",_timestamp, msg.sender); // we store error
        }

		require(msg.sender==cars[_carId].owner);  
        */

		
		statusCount++;
		
        statusChanges[statusCount] = Status(statusCount, _carId, _active,_timestamp, msg.sender); // the global struc
        cars[_carId].activeStory.push(statusCount); // we store the activeStory reference in the corresponding car
		
		// now we update the local register, to have fast access 
		cars[_carId].active = _active;	
        emit changeStatusEvent(); // trigger event 
    }
	
	function retrieveHash (uint _carId) public view returns (bytes32){ 
        //computehash according to unique characteristics
        // this example hashes a transaction as a whole and info of the car
		// we can also just hash the info of the car. 
        return keccak256(abi.encodePacked(block.number,msg.data, cars[_carId].id, cars[_carId].name, cars[_carId].vastidor, cars[_carId].numberofupdates, cars[_carId].actualversion, cars[_carId].owner));
    }
	
	
	// getters structs of a car
	
	// get the array of story of a product, later we can loop them using getters to obtain the data
    function getStroriesCar (uint _carId) public view returns (uint [] memory)  {
        require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks
        require(msg.sender==cars[_carId].owner); 
       

        return cars[_carId].updateStory;
    }
	
	// get the array of changes of a product, later we can loop them using getters to obtain the data
    function getChangesCar (uint _carId) public view returns (uint [] memory)  {
        require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks
        require(msg.sender==cars[_carId].owner); 
        

        return cars[_carId].activeStory;
    }
	
	
	
	// getters specific number of story or status
	function getStory (uint _storyId) public view returns (Story memory)  {
        require(_storyId > 0 && _storyId <= storyCount); 
        require(msg.sender==storiesChanges[_storyId].maker); // only if he is the author of the change
        

        return storiesChanges[_storyId];
    }
	
		// getters specific number of story or status
	function getStatus (uint _statusId) public view returns (Status memory)  {
        require(_statusId > 0 && _statusId <= statusCount); 
        require(msg.sender==statusChanges[_statusId].maker); // only if he is the author of the change
        

        return statusChanges[_statusId];
    }
	
	
    // getters global such as number of structs, for statistics
	
	// returns version number of a car.
    function getVersionCar (uint _carId) public view returns (string memory){
        require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks
	    require(msg.sender==cars[_carId].owner);  // only owner has permissions
        

        return cars[_carId].actualversion;
    }
	
	// returns status of a car.
    function getStatusCar (uint _carId) public view returns (bool){
        require(_carId > 0 && _carId <= carsCount);  // security check avoid memory leaks
	    require(msg.sender==cars[_carId].owner);  // only owner has permissions
        

        return cars[_carId].active;
    }
	
	// returns global number of cars, needed to iterate the mapping and to know info.
    function getNumberOfCars () public view returns (uint){
        require(msg.sender==admin);
        
        return carsCount;
    }
	
	// returns global number of stories, needed to iterate the mapping and to know info.
    function getNumberOfStories () public view returns (uint){
        require(msg.sender==admin);
        
        return storyCount;
    }
	
	// returns global number of status, needed to iterate the mapping and to know info.
    function getNumberOfStatus () public view returns (uint){
        require(msg.sender==admin);
        
        return statusCount;
    }

	
}
