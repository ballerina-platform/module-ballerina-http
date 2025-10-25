import ballerina/http;

public type ServerConfig record {
    string host;
    int port;
};

public type OwnerCreated record {|
    *http:Created;
|};

public type OwnerNotFound record {|
    *http:NotFound;
|};

public type PetCreated record {|
    *http:Created;
|};

public type PetNotFound record {|
    *http:NotFound;
|};

public type VisitCreated record {|
    *http:Created;
|};

public type VetCreated record {|
    *http:Created;
|};

public type SpecialtyCreated record {|
    *http:Created;
|};

public type TypeCreated record {|
    *http:Created;
|};
