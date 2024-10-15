// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthRecordManagement {
    enum UserRole { Patient, Hospital, InsuranceCompany }

    struct HealthRecord {
        string ipfsHash;
        address patient;
        address hospital;
        uint256 timestamp;
    }

    mapping(address => UserRole) public userRoles;
    mapping(address => HealthRecord[]) private patientRecords;

    event RecordUploaded(address indexed patient, address indexed hospital, string ipfsHash);
    event RecordRetrieved(address indexed requester, address indexed patient, string ipfsHash);

    modifier onlyHospital() {
        require(userRoles[msg.sender] == UserRole.Hospital, "Only hospitals can perform this action");
        _;
    }

    modifier onlyInsuranceCompany() {
        require(userRoles[msg.sender] == UserRole.InsuranceCompany, "Only insurance companies can perform this action");
        _;
    }

    constructor() {
        userRoles[msg.sender] = UserRole.Patient; // Contract deployer is set as the first patient
    }

    function registerUser(address _user, UserRole _role) public {
        require(userRoles[_user] == UserRole(0), "User already registered");
        userRoles[_user] = _role;
    }

    function uploadRecord(address _patientAddress, string memory _ipfsHash) public onlyHospital {
        require(userRoles[_patientAddress] == UserRole.Patient, "Invalid patient address");
        
        HealthRecord memory newRecord = HealthRecord({
            ipfsHash: _ipfsHash,
            patient: _patientAddress,
            hospital: msg.sender,
            timestamp: block.timestamp
        });

        patientRecords[_patientAddress].push(newRecord);
        emit RecordUploaded(_patientAddress, msg.sender, _ipfsHash);
    }

    function getRecordCount(address _patientAddress) public view returns (uint256) {
        require(msg.sender == _patientAddress || userRoles[msg.sender] == UserRole.InsuranceCompany, "Unauthorized access");
        return patientRecords[_patientAddress].length;
    }

    function getRecord(address _patientAddress, uint256 _index) public returns (string memory, address, uint256) {
        require(msg.sender == _patientAddress || userRoles[msg.sender] == UserRole.InsuranceCompany, "Unauthorized access");
        require(_index < patientRecords[_patientAddress].length, "Invalid record index");

        HealthRecord memory record = patientRecords[_patientAddress][_index];
        emit RecordRetrieved(msg.sender, _patientAddress, record.ipfsHash);
        return (record.ipfsHash, record.hospital, record.timestamp);
    }
}
