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

const OWNER_NOT_FOUND_TYPE = "/problems/owner-not-found";
const PET_NOT_FOUND_TYPE = "/problems/pet-not-found";
const VISIT_NOT_FOUND_TYPE = "/problems/visit-not-found";
const VET_NOT_FOUND_TYPE = "/problems/vet-not-found";
const SPECIALTY_NOT_FOUND_TYPE = "/problems/specialty-not-found";
const PET_TYPE_NOT_FOUND_TYPE = "/problems/pet-type-not-found";
const VALIDATION_ERROR_TYPE = "/problems/validation-error";
const CONFLICT_ERROR_TYPE = "/problems/conflict";
const DATABASE_ERROR_TYPE = "/problems/database-error";
