// Solidity Smart Contract 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrenatalDiagnosticRegistry {
    address public admin;

    enum Role { None, Radiologist, Authority }
    mapping(address => Role) public userRoles;

    struct DiagnosticReport {
        address hospital;
        string ipfsHash;
        uint timestamp;
        bool genderDisclosed;
        bool approved;
    }

    mapping(address => DiagnosticReport[]) public records;

    event ReportUploaded(address indexed patient, address indexed hospital, uint indexed reportIndex);
    event ReportApproved(address indexed patient, uint indexed reportIndex);
    event GenderDisclosureViolation(address indexed patient, uint indexed reportIndex);
    event UserRegistered(address indexed user, Role role);

    constructor() {
        admin = msg.sender;
        userRoles[admin] = Role.Authority;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(userRoles[msg.sender] == _role, "Unauthorized role.");
        _;
    }

    function registerUser(address _user, Role _role) public onlyAdmin {
        require(_role != Role.None, "Invalid role");
        userRoles[_user] = _role;
        emit UserRegistered(_user, _role);
    }

    function uploadReport(address _patient, string memory _ipfsHash, bool _genderDisclosed)
        public
        onlyRole(Role.Radiologist)
    {
        DiagnosticReport memory newReport = DiagnosticReport({
            hospital: msg.sender,
            ipfsHash: _ipfsHash,
            timestamp: block.timestamp,
            genderDisclosed: _genderDisclosed,
            approved: false
        });

        records[_patient].push(newReport);
        emit ReportUploaded(_patient, msg.sender, records[_patient].length - 1);

        if (_genderDisclosed) {
            emit GenderDisclosureViolation(_patient, records[_patient].length - 1);
        }
    }

    function approveReport(address _patient, uint _index)
        public
        onlyRole(Role.Authority)
    {
        require(_index < records[_patient].length, "Invalid report index");
        records[_patient][_index].approved = true;
        emit ReportApproved(_patient, _index);
    }

    function getReports(address _patient) public view returns (DiagnosticReport[] memory) {
        return records[_patient];
    }

    function getRole(address _user) public view returns (string memory) {
        Role r = userRoles[_user];
        if (r == Role.Radiologist) return "Radiologist";
        if (r == Role.Authority) return "Authority";
        return "None";
    }
}