import ballerina/http;
import ballerina/time;

public isolated function createNotFoundProblem(string detail, string problemType = "/problems/not-found", string? instance = ()) returns NotFoundProblem {
    return {
        body: {
            'type: problemType,
            title: "Not Found",
            status: http:STATUS_NOT_FOUND,
            detail,
            instance,
            timestamp: time:utcNow()
        }
    };
}

public isolated function createBadRequestProblem(string detail, json? validationErrors = (), string? instance = ()) returns BadRequestProblem {
    ProblemDetails problemDetails = {
        'type: VALIDATION_ERROR_TYPE,
        title: "Bad Request",
        status: http:STATUS_BAD_REQUEST,
        detail,
        instance,
        timestamp: time:utcNow()
    };

    if validationErrors is json {
        problemDetails["validationErrors"] = validationErrors;
    }

    return {
        body: problemDetails
    };
}

public isolated function createConflictProblem(string detail, string? instance = ()) returns ConflictProblem {
    return {
        body: {
            'type: CONFLICT_ERROR_TYPE,
            title: "Conflict",
            status: http:STATUS_CONFLICT,
            detail,
            instance,
            timestamp: time:utcNow()
        }
    };
}

public isolated function createInternalServerErrorProblem(string detail, string? errorMessage = (), string? instance = ()) returns InternalServerErrorProblem {
    ProblemDetails problemDetails = {
        'type: DATABASE_ERROR_TYPE,
        title: "Internal Server Error",
        status: http:STATUS_INTERNAL_SERVER_ERROR,
        detail,
        instance,
        timestamp: time:utcNow()
    };

    if errorMessage is string {
        problemDetails["errorDetail"] = errorMessage;
    }

    return {
        body: problemDetails
    };
}

isolated function validateOwnerInput(string firstName, string lastName, string telephone) returns string? {
    if firstName.trim().length() == 0 {
        return "First name cannot be empty";
    }
    if lastName.trim().length() == 0 {
        return "Last name cannot be empty";
    }
    if telephone.trim().length() == 0 {
        return "Telephone cannot be empty";
    }
    if telephone.trim().length() < 10 {
        return "Telephone must be at least 10 digits";
    }
    return ();
}

isolated function validateVetInput(string firstName, string lastName) returns string? {
    if firstName.trim().length() == 0 {
        return "First name cannot be empty";
    }
    if lastName.trim().length() == 0 {
        return "Last name cannot be empty";
    }
    return ();
}
