import petclinic.db;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import ballerina/sql;

configurable int port = 9966;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /petclinic/api on new http:Listener(port) {

    private final db:Client dbClient;

    function init() returns error? {
        self.dbClient = check new ();
        log:printInfo("Pet Clinic API started successfully on port " + port.toString());
    }

    isolated resource function get owners(string? lastName = ()) returns db:Owner[]|InternalServerErrorProblem {
        do {
            sql:ParameterizedQuery whereClause =
                lastName is string
                ? `last_name = ${lastName}`
                : ``;
            stream<db:Owner, persist:Error?> ownersStream = self.dbClient->/owners.get(whereClause = whereClause);

            db:Owner[] owners = check from db:Owner owner in ownersStream
                select owner;

            log:printDebug(string `Retrieved ${owners.length()} owner(s)` + (lastName is string ? string ` with last name: ${lastName}` : ""));
            return owners;
        } on fail error e {
            log:printError("Failed to retrieve owners", 'error = e, lastName = lastName);
            return createInternalServerErrorProblem("Failed to retrieve owners from database", e.message());
        }
    }

    isolated resource function post owners(db:OwnerInsert owner) returns CreatedResponse|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Validate input
            string? validationError = validateOwnerInput(owner.firstName, owner.lastName, owner.telephone);
            if validationError is string {
                return createBadRequestProblem(validationError);
            }

            int[] result = check self.dbClient->/owners.post([owner]);

            log:printInfo(string `Created owner with ID: ${result[0]}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            log:printError("Failed to create owner", 'error = e, owner = owner);
            return createInternalServerErrorProblem("Failed to create owner", e.message());
        }
    }

    isolated resource function get owners/[int ownerId]() returns db:Owner|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Owner owner = check self.dbClient->/owners/[ownerId]();
            log:printDebug(string `Retrieved owner with ID: ${ownerId}`);
            return owner;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Owner not found with ID: ${ownerId}`);

                return createNotFoundProblem(string `Owner with ID ${ownerId} not found`, OWNER_NOT_FOUND_TYPE, string `/owners/${ownerId}`);
            }
            log:printError("Failed to retrieve owner", 'error = e, ownerId = ownerId);
            return createInternalServerErrorProblem(string `Failed to retrieve owner with ID ${ownerId}`, e.message());
        }
    }

    isolated resource function put owners/[int ownerId](db:OwnerUpdate owner) returns db:Owner|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Owner updatedOwner = check self.dbClient->/owners/[ownerId].put(owner);
            log:printInfo(string `Updated owner with ID: ${ownerId}`);
            return updatedOwner;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Owner not found for update with ID: ${ownerId}`);
                return createNotFoundProblem(string `Owner with ID ${ownerId} not found`, OWNER_NOT_FOUND_TYPE,
                        string `/owners/${ownerId}`);
            }
            log:printError("Failed to update owner", 'error = e, ownerId = ownerId);
            return createInternalServerErrorProblem(string `Failed to update owner with ID ${ownerId}`, e.message());
        }
    }

    isolated resource function delete owners/[int ownerId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/owners/[ownerId].delete();
            log:printInfo(string `Deleted owner with ID: ${ownerId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Owner not found for deletion with ID: ${ownerId}`);
                return createNotFoundProblem(string `Owner with ID ${ownerId} not found`, OWNER_NOT_FOUND_TYPE,
                        string `/owners/${ownerId}`);
            }
            log:printError("Failed to delete owner", 'error = e, ownerId = ownerId);
            return createInternalServerErrorProblem(string `Failed to delete owner with ID ${ownerId}`, e.message());
        }
    }

    isolated resource function post owners/[int ownerId]/pets(db:PetInsert pet) returns CreatedResponse|NotFoundProblem|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Verify owner exists
            db:Owner _ = check self.dbClient->/owners/[ownerId]();

            // Validate that the pet's ownerId matches the path parameter
            if pet.ownerId != ownerId {
                return createBadRequestProblem(string `Pet owner ID ${pet.ownerId} does not match URL owner ID ${ownerId}`);
            }

            int[] result = check self.dbClient->/pets.post([pet]);

            log:printInfo(string `Created pet with ID: ${result[0]} for owner ${ownerId}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Owner not found with ID: ${ownerId}`);
                return createNotFoundProblem(string `Owner with ID ${ownerId} not found`, OWNER_NOT_FOUND_TYPE,
                        string `/owners/${ownerId}`);
            }
            log:printError("Failed to create pet", 'error = e, ownerId = ownerId, pet = pet);
            return createInternalServerErrorProblem(string `Failed to create pet for owner ${ownerId}`, e.message());
        }
    }

    isolated resource function post owners/[int ownerId]/pets/[int petId]/visits(db:VisitInsert visit) returns CreatedResponse|NotFoundProblem|ConflictProblem|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Verify pet exists and belongs to the owner
            db:Pet pet = check self.dbClient->/pets/[petId]();

            if pet.ownerId != ownerId {
                return createConflictProblem(string `Pet ${petId} does not belong to owner ${ownerId}`,
                        string `/owners/${ownerId}/pets/${petId}`);
            }

            // Validate that the visit's petId matches the path parameter
            if visit.petId != petId {
                return createBadRequestProblem(string `Visit pet ID ${visit.petId} does not match URL pet ID ${petId}`);
            }

            int[] result = check self.dbClient->/visits.post([visit]);

            log:printInfo(string `Created visit with ID: ${result[0]} for pet ${petId}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet not found with ID: ${petId}`);
                return createNotFoundProblem(string `Pet with ID ${petId} not found`, PET_NOT_FOUND_TYPE,
                        string `/pets/${petId}`);
            }
            log:printError("Failed to create visit", 'error = e, ownerId = ownerId, petId = petId, visit = visit);
            return createInternalServerErrorProblem(string `Failed to create visit for pet ${petId}`, e.message());
        }
    }

    isolated resource function get pets() returns db:Pet[]|InternalServerErrorProblem {
        do {
            stream<db:Pet, persist:Error?> petsStream = self.dbClient->/pets.get();

            db:Pet[] pets = check from db:Pet pet in petsStream
                select pet;

            log:printDebug(string `Retrieved ${pets.length()} pet(s)`);
            return pets;
        } on fail error e {
            log:printError("Failed to retrieve pets", 'error = e);
            return createInternalServerErrorProblem("Failed to retrieve pets from database", e.message());
        }
    }

    isolated resource function get pets/[int petId]() returns db:Pet|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Pet pet = check self.dbClient->/pets/[petId]();
            log:printDebug(string `Retrieved pet with ID: ${petId}`);
            return pet;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet not found with ID: ${petId}`);
                return createNotFoundProblem(string `Pet with ID ${petId} not found`, PET_NOT_FOUND_TYPE,
                        string `/pets/${petId}`);
            }
            log:printError("Failed to retrieve pet", 'error = e, petId = petId);
            return createInternalServerErrorProblem(string `Failed to retrieve pet with ID ${petId}`, e.message());
        }
    }

    isolated resource function put pets/[int petId](db:PetUpdate pet) returns db:Pet|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Pet updatedPet = check self.dbClient->/pets/[petId].put(pet);
            log:printInfo(string `Updated pet with ID: ${petId}`);
            return updatedPet;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet not found for update with ID: ${petId}`);
                return createNotFoundProblem(string `Pet with ID ${petId} not found`, PET_NOT_FOUND_TYPE,
                        string `/pets/${petId}`);
            }
            log:printError("Failed to update pet", 'error = e, petId = petId);
            return createInternalServerErrorProblem(string `Failed to update pet with ID ${petId}`, e.message());
        }
    }

    isolated resource function delete pets/[int petId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/pets/[petId].delete();
            log:printInfo(string `Deleted pet with ID: ${petId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet not found for deletion with ID: ${petId}`);
                return createNotFoundProblem(string `Pet with ID ${petId} not found`, PET_NOT_FOUND_TYPE,
                        string `/pets/${petId}`);
            }
            log:printError("Failed to delete pet", 'error = e, petId = petId);
            return createInternalServerErrorProblem(string `Failed to delete pet with ID ${petId}`, e.message());
        }
    }

    isolated resource function get visits/[int visitId]() returns db:Visit|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Visit visit = check self.dbClient->/visits/[visitId]();
            log:printDebug(string `Retrieved visit with ID: ${visitId}`);
            return visit;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Visit not found with ID: ${visitId}`);
                return createNotFoundProblem(string `Visit with ID ${visitId} not found`, VISIT_NOT_FOUND_TYPE,
                        string `/visits/${visitId}`);
            }
            log:printError("Failed to retrieve visit", 'error = e, visitId = visitId);
            return createInternalServerErrorProblem(string `Failed to retrieve visit with ID ${visitId}`, e.message());
        }
    }

    isolated resource function put visits/[int visitId](db:VisitUpdate visit) returns db:Visit|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Visit updatedVisit = check self.dbClient->/visits/[visitId].put(visit);
            log:printInfo(string `Updated visit with ID: ${visitId}`);
            return updatedVisit;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Visit not found for update with ID: ${visitId}`);
                return createNotFoundProblem(string `Visit with ID ${visitId} not found`, VISIT_NOT_FOUND_TYPE,
                        string `/visits/${visitId}`);
            }
            log:printError("Failed to update visit", 'error = e, visitId = visitId);
            return createInternalServerErrorProblem(string `Failed to update visit with ID ${visitId}`, e.message());
        }
    }

    isolated resource function delete visits/[int visitId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/visits/[visitId].delete();
            log:printInfo(string `Deleted visit with ID: ${visitId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Visit not found for deletion with ID: ${visitId}`);
                return createNotFoundProblem(string `Visit with ID ${visitId} not found`, VISIT_NOT_FOUND_TYPE,
                        string `/visits/${visitId}`);
            }
            log:printError("Failed to delete visit", 'error = e, visitId = visitId);
            return createInternalServerErrorProblem(string `Failed to delete visit with ID ${visitId}`, e.message());
        }
    }

    // ===== Vet Endpoints =====

    isolated resource function get vets() returns db:Vet[]|InternalServerErrorProblem {
        do {
            stream<db:Vet, persist:Error?> vetsStream = self.dbClient->/vets();

            db:Vet[] vets = check from db:Vet vet in vetsStream
                select vet;

            log:printDebug(string `Retrieved ${vets.length()} vet(s)`);
            return vets;
        } on fail error e {
            log:printError("Failed to retrieve vets", 'error = e);
            return createInternalServerErrorProblem("Failed to retrieve vets from database", e.message());
        }
    }

    isolated resource function post vets(db:VetInsert vet) returns CreatedResponse|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Validate input
            string? validationError = validateVetInput(vet.firstName, vet.lastName);
            if validationError is string {
                return createBadRequestProblem(validationError);
            }

            int[] result = check self.dbClient->/vets.post([vet]);

            log:printInfo(string `Created vet with ID: ${result[0]}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            log:printError("Failed to create vet", 'error = e, vet = vet);
            return createInternalServerErrorProblem("Failed to create vet", e.message());
        }
    }

    isolated resource function get vets/[int vetId]() returns db:Vet|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Vet vet = check self.dbClient->/vets/[vetId]();
            log:printDebug(string `Retrieved vet with ID: ${vetId}`);
            return vet;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Vet not found with ID: ${vetId}`);
                return createNotFoundProblem(string `Vet with ID ${vetId} not found`, VET_NOT_FOUND_TYPE,
                        string `/vets/${vetId}`);
            }
            log:printError("Failed to retrieve vet", 'error = e, vetId = vetId);
            return createInternalServerErrorProblem(string `Failed to retrieve vet with ID ${vetId}`, e.message());
        }
    }

    isolated resource function put vets/[int vetId](db:VetUpdate vet) returns db:Vet|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Vet updatedVet = check self.dbClient->/vets/[vetId].put(vet);
            log:printInfo(string `Updated vet with ID: ${vetId}`);
            return updatedVet;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Vet not found for update with ID: ${vetId}`);
                return createNotFoundProblem(string `Vet with ID ${vetId} not found`, VET_NOT_FOUND_TYPE,
                        string `/vets/${vetId}`);
            }
            log:printError("Failed to update vet", 'error = e, vetId = vetId);
            return createInternalServerErrorProblem(string `Failed to update vet with ID ${vetId}`, e.message());
        }
    }

    isolated resource function delete vets/[int vetId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/vets/[vetId].delete();
            log:printInfo(string `Deleted vet with ID: ${vetId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Vet not found for deletion with ID: ${vetId}`);
                return createNotFoundProblem(string `Vet with ID ${vetId} not found`, VET_NOT_FOUND_TYPE,
                        string `/vets/${vetId}`);
            }
            log:printError("Failed to delete vet", 'error = e, vetId = vetId);
            return createInternalServerErrorProblem(string `Failed to delete vet with ID ${vetId}`, e.message());
        }
    }

    // ===== Specialty Endpoints =====
    isolated resource function get specialties() returns db:Specialty[]|InternalServerErrorProblem {
        do {
            stream<db:Specialty, persist:Error?> specialtyStream = self.dbClient->/specialties();

            db:Specialty[] specialties = check from db:Specialty specialty in specialtyStream
                select specialty;

            log:printDebug(string `Retrieved ${specialties.length()} specialt(y/ies)`);
            return specialties;
        } on fail error e {
            log:printError("Failed to retrieve specialties", 'error = e);
            return createInternalServerErrorProblem("Failed to retrieve specialties from database", e.message());
        }
    }

    isolated resource function post specialties(db:SpecialtyInsert specialty) returns CreatedResponse|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Validate input
            if specialty.name.trim().length() == 0 {
                return createBadRequestProblem("Specialty name cannot be empty");
            }

            int[] result = check self.dbClient->/specialties.post([specialty]);

            log:printInfo(string `Created specialty with ID: ${result[0]}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            log:printError("Failed to create specialty", 'error = e, specialty = specialty);
            return createInternalServerErrorProblem("Failed to create specialty", e.message());
        }
    }

    isolated resource function get specialties/[int specialtyId]() returns db:Specialty|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Specialty specialty = check self.dbClient->/specialties/[specialtyId]();
            log:printDebug(string `Retrieved specialty with ID: ${specialtyId}`);
            return specialty;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Specialty not found with ID: ${specialtyId}`);
                return createNotFoundProblem(string `Specialty with ID ${specialtyId} not found`, SPECIALTY_NOT_FOUND_TYPE,
                        string `/specialties/${specialtyId}`);
            }
            log:printError("Failed to retrieve specialty", 'error = e, specialtyId = specialtyId);
            return createInternalServerErrorProblem(string `Failed to retrieve specialty with ID ${specialtyId}`, e.message());
        }
    }

    isolated resource function put specialties/[int specialtyId](db:SpecialtyUpdate specialty) returns db:Specialty|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Specialty updatedSpecialty = check self.dbClient->/specialties/[specialtyId].put(specialty);
            log:printInfo(string `Updated specialty with ID: ${specialtyId}`);
            return updatedSpecialty;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Specialty not found for update with ID: ${specialtyId}`);
                return createNotFoundProblem(string `Specialty with ID ${specialtyId} not found`, SPECIALTY_NOT_FOUND_TYPE,
                        string `/specialties/${specialtyId}`);
            }
            log:printError("Failed to update specialty", 'error = e, specialtyId = specialtyId);
            return createInternalServerErrorProblem(string `Failed to update specialty with ID ${specialtyId}`, e.message());
        }
    }

    isolated resource function delete specialties/[int specialtyId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/specialties/[specialtyId].delete();
            log:printInfo(string `Deleted specialty with ID: ${specialtyId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Specialty not found for deletion with ID: ${specialtyId}`);
                return createNotFoundProblem(string `Specialty with ID ${specialtyId} not found`, SPECIALTY_NOT_FOUND_TYPE,
                        string `/specialties/${specialtyId}`);
            }
            log:printError("Failed to delete specialty", 'error = e, specialtyId = specialtyId);
            return createInternalServerErrorProblem(string `Failed to delete specialty with ID ${specialtyId}`, e.message());
        }
    }

    // ===== Vet Specialty Endpoints =====

    isolated resource function get vetspecialties/[int vetId]() returns db:VetSpecialty[]|NotFoundProblem|InternalServerErrorProblem {
        do {
            // Verify vet exists
            db:VetWithRelations _ = check self.dbClient->/vets/[vetId]();

            sql:ParameterizedQuery whereClause = `vet_id = ${vetId}`;
            stream<db:VetSpecialty, persist:Error?> vetSpecialtyStream =
                self.dbClient->/vetspecialties.get(whereClause = whereClause);

            db:VetSpecialty[] vetSpecialties = check from db:VetSpecialty vs in vetSpecialtyStream
                select vs;

            log:printDebug(string `Retrieved ${vetSpecialties.length()} specialt(y/ies) for vet ${vetId}`);
            return vetSpecialties;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Vet not found with ID: ${vetId}`);
                return createNotFoundProblem(string `Vet with ID ${vetId} not found`, VET_NOT_FOUND_TYPE,
                        string `/vets/${vetId}`);
            }
            log:printError("Failed to retrieve vet specialties", 'error = e, vetId = vetId);
            return createInternalServerErrorProblem(string `Failed to retrieve specialties for vet ${vetId}`, e.message());
        }
    }

    isolated resource function post vetspecialties(db:VetSpecialtyInsert vetSpecialty) returns CreatedArrayResponse|NotFoundProblem|InternalServerErrorProblem {
        do {
            // Verify vet and specialty exist
            db:VetWithRelations _ = check self.dbClient->/vets/[vetSpecialty.vetId]();
            db:SpecialtyWithRelations _ = check self.dbClient->/specialties/[vetSpecialty.specialtyId]();

            int[][] result = check self.dbClient->/vetspecialties.post([vetSpecialty]);

            log:printInfo(string `Assigned specialty ${vetSpecialty.specialtyId} to vet ${vetSpecialty.vetId}`);
            return <CreatedArrayResponse>{
                body: {ids: result}
            };
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug("Vet or specialty not found for vet specialty assignment", vetSpecialty = vetSpecialty);
                return createNotFoundProblem("Vet or specialty not found", "/problems/not-found");
            }
            log:printError("Failed to create vet specialty", 'error = e, vetSpecialty = vetSpecialty);
            return createInternalServerErrorProblem("Failed to assign specialty to vet", e.message());
        }
    }

    isolated resource function delete vetspecialties/[int vetId]/[int specialtyId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/vetspecialties/[vetId]/[specialtyId].delete();
            log:printInfo(string `Removed specialty ${specialtyId} from vet ${vetId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Vet specialty not found for vet ${vetId} and specialty ${specialtyId}`);
                return createNotFoundProblem(string `Specialty ${specialtyId} not assigned to vet ${vetId}`,
                        "/problems/not-found", string `/vetspecialties/${vetId}/${specialtyId}`);
            }
            log:printError("Failed to delete vet specialty", 'error = e, vetId = vetId, specialtyId = specialtyId);
            return createInternalServerErrorProblem(string `Failed to remove specialty ${specialtyId} from vet ${vetId}`, e.message());
        }
    }

    // ===== Pet Type Endpoints =====

    isolated resource function get pettypes() returns db:Type[]|InternalServerErrorProblem {
        do {
            stream<db:Type, persist:Error?> petTypesStream = self.dbClient->/types();

            db:Type[] petTypes = check from db:Type petType in petTypesStream
                select petType;

            log:printDebug(string `Retrieved ${petTypes.length()} pet type(s)`);
            return petTypes;
        } on fail error e {
            log:printError("Failed to retrieve pet types", 'error = e);
            return createInternalServerErrorProblem("Failed to retrieve pet types from database", e.message());
        }
    }

    isolated resource function post pettypes(db:TypeInsert petType) returns CreatedResponse|BadRequestProblem|InternalServerErrorProblem {
        do {
            // Validate input
            if petType.name.trim().length() == 0 {
                return createBadRequestProblem("Pet type name cannot be empty");
            }

            int[] result = check self.dbClient->/types.post([petType]);

            log:printInfo(string `Created pet type with ID: ${result[0]}`);
            return <CreatedResponse>{
                body: {id: result[0]}
            };
        } on fail error e {
            log:printError("Failed to create pet type", 'error = e, petType = petType);
            return createInternalServerErrorProblem("Failed to create pet type", e.message());
        }
    }

    isolated resource function get pettypes/[int petTypeId]() returns db:Type|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Type petType = check self.dbClient->/types/[petTypeId]();
            log:printDebug(string `Retrieved pet type with ID: ${petTypeId}`);
            return petType;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet type not found with ID: ${petTypeId}`);
                return createNotFoundProblem(string `Pet type with ID ${petTypeId} not found`, PET_TYPE_NOT_FOUND_TYPE,
                        string `/pettypes/${petTypeId}`);
            }
            log:printError("Failed to retrieve pet type", 'error = e, petTypeId = petTypeId);
            return createInternalServerErrorProblem(string `Failed to retrieve pet type with ID ${petTypeId}`, e.message());
        }
    }

    isolated resource function put pettypes/[int petTypeId](db:TypeUpdate petType) returns db:Type|NotFoundProblem|InternalServerErrorProblem {
        do {
            db:Type updatedPetType = check self.dbClient->/types/[petTypeId].put(petType);
            log:printInfo(string `Updated pet type with ID: ${petTypeId}`);
            return updatedPetType;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet type not found for update with ID: ${petTypeId}`);
                return createNotFoundProblem(string `Pet type with ID ${petTypeId} not found`, PET_TYPE_NOT_FOUND_TYPE,
                        string `/pettypes/${petTypeId}`);
            }
            log:printError("Failed to update pet type", 'error = e, petTypeId = petTypeId);
            return createInternalServerErrorProblem(string `Failed to update pet type with ID ${petTypeId}`, e.message());
        }
    }

    isolated resource function delete pettypes/[int petTypeId]() returns http:NoContent|NotFoundProblem|InternalServerErrorProblem {
        do {
            _ = check self.dbClient->/types/[petTypeId].delete();
            log:printInfo(string `Deleted pet type with ID: ${petTypeId}`);
            return http:NO_CONTENT;
        } on fail error e {
            if e is persist:NotFoundError {
                log:printDebug(string `Pet type not found for deletion with ID: ${petTypeId}`);
                return createNotFoundProblem(string `Pet type with ID ${petTypeId} not found`, PET_TYPE_NOT_FOUND_TYPE,
                        string `/pettypes/${petTypeId}`);
            }
            log:printError("Failed to delete pet type", 'error = e, petTypeId = petTypeId);
            return createInternalServerErrorProblem(string `Failed to delete pet type with ID ${petTypeId}`, e.message());
        }
    }
}
