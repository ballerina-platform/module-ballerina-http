import ballerina/http;
import ballerina/log;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/time;

// Configuration
configurable ServerConfig serverConfig = ?;
configurable DatabaseConfig databaseConfig = ?;

// Database connection
final postgresql:Client dbClient = check initDbClient();
function initDbClient() returns postgresql:Client|error => new (
    host = databaseConfig.host,
    database = databaseConfig.database,
    username = databaseConfig.username,
    password = databaseConfig.password,
    port = databaseConfig.port
);

// HTTP listener
listener http:Listener httpListener = new (serverConfig.port, config = {
    host: serverConfig.host
});

// Pet Clinic REST API Service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /petclinic/api on httpListener {

    // Initialize database on service start
    public function init() returns error? {
        log:printInfo("Pet Clinic API started successfully");
    }

    // Owner endpoints
    resource function get owners(string? lastName = ()) returns Owner[]|http:InternalServerError {
        Owner[]|error owners = getAllOwners(lastName);
        if owners is error {
            log:printError("Error retrieving owners", owners);
            return createInternalServerError("Error retrieving owners");
        }
        return owners;
    }

    resource function post owners(@http:Payload OwnerFields ownerFields) returns Owner|http:BadRequest|http:InternalServerError {
        Owner|error owner = createOwner(ownerFields);
        if owner is error {
            log:printError("Error creating owner", owner);
            if owner.message().includes("validation") {
                return createBadRequest("Invalid owner data");
            }
            return createInternalServerError("Error creating owner");
        }
        return owner;
    }

    resource function get owners/[int ownerId]() returns Owner|http:NotFound|http:InternalServerError {
        Owner|error? owner = getOwnerById(ownerId);
        if owner is error {
            log:printError("Error retrieving owner", owner);
            return createInternalServerError("Error retrieving owner");
        }
        if owner is () {
            return createNotFound("Owner not found");
        }
        return owner;
    }

    resource function put owners/[int ownerId](@http:Payload OwnerFields ownerFields) returns Owner|http:NotFound|http:BadRequest|http:InternalServerError {
        Owner|error? owner = updateOwner(ownerId, ownerFields);
        if owner is error {
            log:printError("Error updating owner", owner);
            if owner.message().includes("validation") {
                return createBadRequest("Invalid owner data");
            }
            return createInternalServerError("Error updating owner");
        }
        if owner is () {
            return createNotFound("Owner not found");
        }
        return owner;
    }

    resource function delete owners/[int ownerId]() returns Owner|http:NotFound|http:InternalServerError {
        Owner|error? owner = deleteOwner(ownerId);
        if owner is error {
            log:printError("Error deleting owner", owner);
            return createInternalServerError("Error deleting owner");
        }
        if owner is () {
            return createNotFound("Owner not found");
        }
        return owner;
    }

    // Pet endpoints for owners
    resource function post owners/[int ownerId]/pets(@http:Payload PetFields petFields) returns Pet|http:BadRequest|http:NotFound|http:InternalServerError {
        // Verify owner exists
        Owner|error? owner = getOwnerById(ownerId);
        if owner is error {
            return createInternalServerError("Error verifying owner");
        }
        if owner is () {
            return createNotFound("Owner not found");
        }

        Pet|error pet = createPet(ownerId, petFields);
        if pet is error {
            log:printError("Error creating pet", pet);
            if pet.message().includes("validation") {
                return createBadRequest("Invalid pet data");
            }
            return createInternalServerError("Error creating pet");
        }
        return pet;
    }

    // Visit endpoints for owners and pets
    resource function post owners/[int ownerId]/pets/[int petId]/visits(@http:Payload VisitFields visitFields) returns Visit|http:BadRequest|http:NotFound|http:InternalServerError {
        // Verify pet belongs to owner
        Pet|error? pet = getPetById(petId);
        if pet is error {
            return createInternalServerError("Error verifying pet");
        }
        if pet is () || pet.ownerId != ownerId {
            return createNotFound("Pet not found for this owner");
        }

        Visit|error visit = createVisit(ownerId, petId, visitFields);
        if visit is error {
            log:printError("Error creating visit", visit);
            if visit.message().includes("validation") {
                return createBadRequest("Invalid visit data");
            }
            return createInternalServerError("Error creating visit");
        }
        return visit;
    }

    // Pet endpoints
    resource function get pets() returns Pet[]|http:InternalServerError {
        Pet[]|error pets = getAllPets();
        if pets is error {
            log:printError("Error retrieving pets", pets);
            return createInternalServerError("Error retrieving pets");
        }
        return pets;
    }

    resource function get pets/[int petId]() returns Pet|http:NotFound|http:InternalServerError {
        Pet|error? pet = getPetById(petId);
        if pet is error {
            log:printError("Error retrieving pet", pet);
            return createInternalServerError("Error retrieving pet");
        }
        if pet is () {
            return createNotFound("Pet not found");
        }
        return pet;
    }

    resource function put pets/[int petId](@http:Payload Pet pet) returns Pet|http:NotFound|http:BadRequest|http:InternalServerError {
        Pet|error? updatedPet = updatePet(petId, pet);
        if updatedPet is error {
            log:printError("Error updating pet", updatedPet);
            if updatedPet.message().includes("validation") {
                return createBadRequest("Invalid pet data");
            }
            return createInternalServerError("Error updating pet");
        }
        if updatedPet is () {
            return createNotFound("Pet not found");
        }
        return updatedPet;
    }

    resource function delete pets/[int petId]() returns Pet|http:NotFound|http:InternalServerError {
        Pet|error? pet = deletePet(petId);
        if pet is error {
            log:printError("Error deleting pet", pet);
            return createInternalServerError("Error deleting pet");
        }
        if pet is () {
            return createNotFound("Pet not found");
        }
        return pet;
    }

    // Visit endpoints
    resource function get visits/[int visitId]() returns Visit|http:NotFound|http:InternalServerError {
        Visit|error? visit = getVisitById(visitId);
        if visit is error {
            log:printError("Error retrieving visit", visit);
            return createInternalServerError("Error retrieving visit");
        }
        if visit is () {
            return createNotFound("Visit not found");
        }
        return visit;
    }

    resource function put visits/[int visitId](@http:Payload VisitFields visitFields) returns Visit|http:NotFound|http:BadRequest|http:InternalServerError {
        Visit|error? visit = updateVisit(visitId, visitFields);
        if visit is error {
            log:printError("Error updating visit", visit);
            if visit.message().includes("validation") {
                return createBadRequest("Invalid visit data");
            }
            return createInternalServerError("Error updating visit");
        }
        if visit is () {
            return createNotFound("Visit not found");
        }
        return visit;
    }

    resource function delete visits/[int visitId]() returns Visit|http:NotFound|http:InternalServerError {
        Visit|error? visit = deleteVisit(visitId);
        if visit is error {
            log:printError("Error deleting visit", visit);
            return createInternalServerError("Error deleting visit");
        }
        if visit is () {
            return createNotFound("Visit not found");
        }
        return visit;
    }

    // Vet endpoints
    resource function get vets() returns Vet[]|http:InternalServerError {
        Vet[]|error vets = getAllVets();
        if vets is error {
            log:printError("Error retrieving vets", vets);
            return createInternalServerError("Error retrieving vets");
        }
        return vets;
    }

    resource function post vets(@http:Payload Vet vet) returns Vet|http:BadRequest|http:InternalServerError {
        Vet|error createdVet = createVet(vet);
        if createdVet is error {
            log:printError("Error creating vet", createdVet);
            if createdVet.message().includes("validation") {
                return createBadRequest("Invalid vet data");
            }
            return createInternalServerError("Error creating vet");
        }
        return createdVet;
    }

    resource function get vets/[int vetId]() returns Vet|http:NotFound|http:InternalServerError {
        Vet|error? vet = getVetById(vetId);
        if vet is error {
            log:printError("Error retrieving vet", vet);
            return createInternalServerError("Error retrieving vet");
        }
        if vet is () {
            return createNotFound("Vet not found");
        }
        return vet;
    }

    resource function put vets/[int vetId](@http:Payload Vet vet) returns Vet|http:NotFound|http:BadRequest|http:InternalServerError {
        Vet|error? updatedVet = updateVet(vetId, vet);
        if updatedVet is error {
            log:printError("Error updating vet", updatedVet);
            if updatedVet.message().includes("validation") {
                return createBadRequest("Invalid vet data");
            }
            return createInternalServerError("Error updating vet");
        }
        if updatedVet is () {
            return createNotFound("Vet not found");
        }
        return updatedVet;
    }

    resource function delete vets/[int vetId]() returns Vet|http:NotFound|http:InternalServerError {
        Vet|error? vet = deleteVet(vetId);
        if vet is error {
            log:printError("Error deleting vet", vet);
            return createInternalServerError("Error deleting vet");
        }
        if vet is () {
            return createNotFound("Vet not found");
        }
        return vet;
    }

    // Specialty endpoints
    resource function get specialties() returns Specialty[]|http:InternalServerError {
        Specialty[]|error specialties = getAllSpecialties();
        if specialties is error {
            log:printError("Error retrieving specialties", specialties);
            return createInternalServerError("Error retrieving specialties");
        }
        return specialties;
    }

    resource function post specialties(@http:Payload Specialty specialty) returns Specialty|http:BadRequest|http:InternalServerError {
        Specialty|error createdSpecialty = createSpecialty(specialty);
        if createdSpecialty is error {
            log:printError("Error creating specialty", createdSpecialty);
            if createdSpecialty.message().includes("validation") {
                return createBadRequest("Invalid specialty data");
            }
            return createInternalServerError("Error creating specialty");
        }
        return createdSpecialty;
    }

    resource function get specialties/[int specialtyId]() returns Specialty|http:NotFound|http:InternalServerError {
        Specialty|error? specialty = getSpecialtyById(specialtyId);
        if specialty is error {
            log:printError("Error retrieving specialty", specialty);
            return createInternalServerError("Error retrieving specialty");
        }
        if specialty is () {
            return createNotFound("Specialty not found");
        }
        return specialty;
    }

    resource function put specialties/[int specialtyId](@http:Payload Specialty specialty) returns Specialty|http:NotFound|http:BadRequest|http:InternalServerError {
        Specialty|error? updatedSpecialty = updateSpecialty(specialtyId, specialty);
        if updatedSpecialty is error {
            log:printError("Error updating specialty", updatedSpecialty);
            if updatedSpecialty.message().includes("validation") {
                return createBadRequest("Invalid specialty data");
            }
            return createInternalServerError("Error updating specialty");
        }
        if updatedSpecialty is () {
            return createNotFound("Specialty not found");
        }
        return updatedSpecialty;
    }

    resource function delete specialties/[int specialtyId]() returns Specialty|http:NotFound|http:InternalServerError {
        Specialty|error? specialty = deleteSpecialty(specialtyId);
        if specialty is error {
            log:printError("Error deleting specialty", specialty);
            return createInternalServerError("Error deleting specialty");
        }
        if specialty is () {
            return createNotFound("Specialty not found");
        }
        return specialty;
    }

    // Pet Type endpoints
    resource function get pettypes() returns PetType[]|http:InternalServerError {
        PetType[]|error petTypes = getAllPetTypes();
        if petTypes is error {
            log:printError("Error retrieving pet types", petTypes);
            return createInternalServerError("Error retrieving pet types");
        }
        return petTypes;
    }

    resource function post pettypes(@http:Payload PetTypeFields petTypeFields) returns PetType|http:BadRequest|http:InternalServerError {
        PetType|error petType = createPetType(petTypeFields);
        if petType is error {
            log:printError("Error creating pet type", petType);
            if petType.message().includes("validation") {
                return createBadRequest("Invalid pet type data");
            }
            return createInternalServerError("Error creating pet type");
        }
        return petType;
    }

    resource function get pettypes/[int petTypeId]() returns PetType|http:NotFound|http:InternalServerError {
        PetType|error? petType = getPetTypeById(petTypeId);
        if petType is error {
            log:printError("Error retrieving pet type", petType);
            return createInternalServerError("Error retrieving pet type");
        }
        if petType is () {
            return createNotFound("Pet Type not found");
        }
        return petType;
    }

    resource function put pettypes/[int petTypeId](@http:Payload PetType petType) returns PetType|http:NotFound|http:BadRequest|http:InternalServerError {
        PetType|error? updatedPetType = updatePetType(petTypeId, petType);
        if updatedPetType is error {
            log:printError("Error updating pet type", updatedPetType);
            if updatedPetType.message().includes("validation") {
                return createBadRequest("Invalid pet type data");
            }
            return createInternalServerError("Error updating pet type");
        }
        if updatedPetType is () {
            return createNotFound("Pet Type not found");
        }
        return updatedPetType;
    }

    resource function delete pettypes/[int petTypeId]() returns PetType|http:NotFound|http:InternalServerError {
        PetType|error? petType = deletePetType(petTypeId);
        if petType is error {
            log:printError("Error deleting pet type", petType);
            return createInternalServerError("Error deleting pet type");
        }
        if petType is () {
            return createNotFound("Pet type not found");
        }
        return petType;
    }
}

// Helper functions for creating HTTP responses
function createNotFound(string message) returns http:NotFound {
    return {
        body: createProblemDetail(404, "Not Found", message)
    };
}

function createBadRequest(string message) returns http:BadRequest {
    return {
        body: createProblemDetail(400, "Bad Request", message)
    };
}

function createInternalServerError(string message) returns http:InternalServerError {
    return {
        body: createProblemDetail(500, "Internal Server Error", message)
    };
}

function createProblemDetail(int status, string title, string detail) returns ProblemDetail {
    return {
        'type: "http://localhost:9966/petclinic/api",
        title: title,
        status: status,
        detail: detail,
        timestamp: time:utcNow(),
        schemaValidationErrors: []
    };
}
