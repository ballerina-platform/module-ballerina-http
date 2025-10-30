import ballerina/http;
import ballerina/time;

public type ProblemDetails record {|
    string 'type = "/problems/generic-error";
    string title;
    int status;
    string detail;
    string instance?;
    time:Utc timestamp = time:utcNow();
    json...;
|};

public type CreatedResponse record {|
    *http:Created;
    record {|int id;|} body;
|};

public type CreatedArrayResponse record {|
    *http:Created;
    record {|int[][] ids;|} body;
|};

public type BadRequestProblem record {|
    *http:BadRequest;
    ProblemDetails body;
|};

public type NotFoundProblem record {|
    *http:NotFound;
    ProblemDetails body;
|};

public type ConflictProblem record {|
    *http:Conflict;
    ProblemDetails body;
|};

public type InternalServerErrorProblem record {|
    *http:InternalServerError;
    ProblemDetails body;
|};

const string OWNER_NOT_FOUND_TYPE = "/problems/owner-not-found";
const string PET_NOT_FOUND_TYPE = "/problems/pet-not-found";
const string VISIT_NOT_FOUND_TYPE = "/problems/visit-not-found";
const string VET_NOT_FOUND_TYPE = "/problems/vet-not-found";
const string SPECIALTY_NOT_FOUND_TYPE = "/problems/specialty-not-found";
const string PET_TYPE_NOT_FOUND_TYPE = "/problems/pet-type-not-found";
const string VALIDATION_ERROR_TYPE = "/problems/validation-error";
const string CONFLICT_ERROR_TYPE = "/problems/conflict";
const string DATABASE_ERROR_TYPE = "/problems/database-error";
