import ballerina/time;

// Core data types based on OpenAPI schemas

public type ProblemDetail record {
    string 'type;
    string title;
    int status;
    string detail;
    time:Utc timestamp;
    ValidationMessage[] schemaValidationErrors?;
};

public type ValidationMessage record {
    string message;
    map<anydata> additionalProperties?;
};

public type Specialty record {
    int id?;
    string name;
};

public type PetType record {
    int id?;
    string name;
};

public type PetTypeFields record {
    string name;
};

public type Vet record {
    int id?;
    string firstName;
    string lastName;
    Specialty[] specialties;
};

public type Visit record {
    int id?;
    string date?;
    string description;
    int petId;
};

public type VisitFields record {
    string date?;
    string description;
};

public type Pet record {
    int id?;
    string name;
    string birthDate;
    PetType 'type;
    int ownerId?;
    Visit[] visits?;
};

public type PetFields record {
    string name;
    string birthDate;
    PetType 'type;
};

public type Owner record {
    int id?;
    string firstName;
    string lastName;
    string address;
    string city;
    string telephone;
    Pet[] pets?;
};

public type OwnerFields record {
    string firstName;
    string lastName;
    string address;
    string city;
    string telephone;
};

// Database configuration type
public type DatabaseConfig record {
    string host;
    int port;
    string database;
    string username;
    string password;
};

public type ServerConfig record {
    string host;
    int port;
};
