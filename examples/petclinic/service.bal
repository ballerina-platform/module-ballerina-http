import ballerina/http;
import petclinic.db;
import ballerina/log;
import ballerina/persist;
import ballerina/sql;

configurable ServerConfig serverConfig = ?;

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

    private final db:Client dbClient;

    function init() returns error? {
        self.dbClient = check new();
        log:printInfo("Pet Clinic API started successfully");
    }

    // Owner endpoints
    isolated resource function get owners(string? lastName = ()) returns db:Owner[]|error {
        lock {
            sql:ParameterizedQuery whereClause = 
                lastName is string 
                ? `last_name = ${lastName}`
                : ``;

            stream<db:Owner, persist:Error?> ownersStream = 
                self.dbClient->/owners.get(whereClause = whereClause);

            return from db:Owner owner in ownersStream
                   select owner;
        }
    }

    isolated resource function post owners(db:OwnerInsert owner) returns http:InternalServerError & readonly|OwnerCreated|http:Conflict & readonly{
        lock {
            int[]|persist:Error result = self.dbClient->/owners.post([owner]);
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <OwnerCreated> {
                body: {
                    insertedId: result[0]
                }
            };   
        }
    }

    isolated resource function get owners/[int ownerId]() returns http:InternalServerError & readonly|http:NotFound & readonly|db:Owner {
        lock {
            db:Owner|persist:Error result = self.dbClient->/owners/[ownerId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put owners/[int ownerId](db:OwnerUpdate owner) returns http:InternalServerError & readonly|http:NotFound & readonly|db:Owner {
        lock {
            db:Owner|persist:Error result = self.dbClient->/owners/[ownerId].put(owner);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete owners/[int ownerId]() returns http:NoContent | http:InternalServerError{
        lock {
            db:Owner|persist:Error result = self.dbClient->/owners/[ownerId].delete();
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Pet endpoints for owners
    isolated resource function post owners/[int ownerId]/pets(db:PetInsert pet) returns http:InternalServerError | OwnerNotFound | PetCreated | error {
        lock {
            db:Owner|persist:Error result = self.dbClient->/owners/[ownerId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return <OwnerNotFound> {
                            body: {
                                message: string `Owner ${ownerId} not found`
                            }
                        };
                }
                return http:INTERNAL_SERVER_ERROR;
            }

            int[]|persist:Error petInsertResult = self.dbClient->/pets.post([pet]);
            if petInsertResult is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <PetCreated> {
                body: {
                    insertedId: petInsertResult[0]
                }
            };
        }
    }

    // Visit endpoints for owners and pets
    isolated resource function post owners/[int ownerId]/pets/[int petId]/visits(db:VisitInsert visit) returns http:Conflict | http:InternalServerError | PetNotFound | VisitCreated | error{

        lock {
            db:Pet|persist:Error pet = self.dbClient->/pets/[petId]();
            if pet is persist:Error {
                if pet is persist:NotFoundError {
                    return <PetNotFound> {
                            body: {
                                message: string `Pet ${petId} not found`
                            }
                        };
                }
                return http:INTERNAL_SERVER_ERROR;
            }

            if (pet.ownerId != ownerId) {
                return <http:Conflict> {
                    body:  "Pet not found for this owner"
                };
            }

            int[]|persist:Error visitInsertResult = self.dbClient->/visits.post([visit]);
            if visitInsertResult is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <VisitCreated> {
                body: {
                    insertedId: visitInsertResult[0]
                }
            };

        }
    }

    // Pet endpoints
    isolated resource function get pets() returns db:Pet[] | error {
        lock {
            stream<db:Pet, persist:Error?> petsStream = self.dbClient->/pets.get();
            return from db:Pet pet in petsStream
                   select pet;
        }
    }

    isolated resource function get pets/[int petId]() returns db:Pet | http:NotFound | http:InternalServerError | error {
        lock {
            db:Pet|persist:Error result = self.dbClient->/pets/[petId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put pets/[int petId](db:PetUpdate pet) returns db:Pet | http:NotFound | http:InternalServerError | error {
        lock {
            db:Pet|persist:Error result = self.dbClient->/pets/[petId].put(pet);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete pets/[int petId]() returns http:NoContent | http:InternalServerError{
        lock {
            db:Pet|persist:Error result = self.dbClient->/pets/[petId].delete();
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Visit endpoints
    isolated resource function get visits/[int visitId]() returns db:Visit | http:NotFound | http:InternalServerError | error {
        lock {
            db:Visit|persist:Error result = self.dbClient->/visits/[visitId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put visits/[int visitId](db:VisitUpdate visit) returns db:Visit | http:NotFound | http:InternalServerError | error {
        lock {
            db:Visit|persist:Error result = self.dbClient->/visits/[visitId].put(visit);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete visits/[int visitId]() returns http:NoContent | http:InternalServerError | error {
        lock {
            db:Visit|persist:Error result = self.dbClient->/visits/[visitId].delete;
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Vet endpoints
    isolated resource function get vets() returns db:Vet[] | error {
        lock {
            stream<db:Vet, persist:Error?> vetsStream = self.dbClient->/vets();
            return from db:Vet vet in vetsStream
                   select vet;
        }
    }

    isolated resource function post vets(db:VetInsert vet) returns http:InternalServerError & readonly|VetCreated|http:Conflict & readonly {
        lock {
            int[]|persist:Error result = self.dbClient->/vets.post([vet]);
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <VetCreated> {
                body: {
                    insertedId: result[0]
                }
            };
        }
    }

    isolated resource function get vets/[int vetId]() returns db:Vet | http:NotFound | http:InternalServerError | error {
        lock {
            db:Vet|persist:Error result = self.dbClient->/vets/[vetId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put vets/[int vetId](db:VetUpdate vet) returns db:Vet | http:NotFound | http:InternalServerError | error {
        lock {
            db:Vet|persist:Error result = self.dbClient->/vets/[vetId].put(vet);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete vets/[int vetId]() returns http:NoContent | http:InternalServerError {
        lock {
            db:Vet|persist:Error result = self.dbClient->/vets/[vetId].delete;
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Specialty endpoints
    isolated resource function get specialties() returns db:Specialty[] | error {
        lock {
            stream<db:Specialty, persist:Error?> specialtyStream = self.dbClient->/specialties();
            return from db:Specialty specialty in specialtyStream
                   select specialty;
        }
    }

    isolated resource function post specialties(db:SpecialtyInsert specialty) returns http:InternalServerError & readonly|SpecialtyCreated|http:Conflict & readonly {
        lock {
            int[]|persist:Error result = self.dbClient->/specialties.post([specialty]);
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <SpecialtyCreated> {
                body: {
                    insertedId: result[0]
                }
            };
        }
    }

    isolated resource function get specialties/[int specialtyId]() returns db:Specialty | http:NotFound | http:InternalServerError | error {
        lock {
            db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put specialties/[int specialtyId](db:SpecialtyUpdate specialty) returns db:Specialty | http:NotFound | http:InternalServerError | error {
        lock {
            db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId].put(specialty);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete specialties/[int specialtyId]() returns http:NoContent | http:InternalServerError {
        lock {
            db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId].delete;
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Vet Speciality endpoints
    isolated resource function get vetspecialties/[int vetId]() returns db:VetSpecialty[] | http:NotFound | http:InternalServerError | error {
        lock {
            db:Vet|persist:Error result = self.dbClient->/vets/[vetId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return <http:NotFound> {
                        body: string `Vet ${vetId} not found`
                    };
                }
                return http:INTERNAL_SERVER_ERROR;
            }

            sql:ParameterizedQuery whereClause = `vet_id = ${vetId}`;

            stream<db:VetSpecialty, persist:Error?> vetSpecialtyStream = 
                self.dbClient->/vetspecialties.get(whereClause = whereClause);

            return from db:VetSpecialty vs in vetSpecialtyStream
                   select vs;
        }
    }

    isolated resource function post vetspecialties(db:VetSpecialtyInsert vetSpecialty) returns http:InternalServerError & readonly|SpecialtyCreated|http:Conflict & readonly {
        lock {
            int[][]|persist:Error result = self.dbClient->/vetspecialties.post([vetSpecialty]);
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <SpecialtyCreated> {
                body: {
                    insertedId: result
                }
            };
        }
    }

    isolated resource function delete vetspecialties/[int vetId]/[int specialtyId]() returns http:NoContent | http:InternalServerError | error {
        lock {
            db:VetSpecialty|persist:Error result = self.dbClient->/vetspecialties/[vetId]/[specialtyId].delete;
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }

    // Pet Type endpoints
    isolated resource function get pettypes() returns db:Type[] | error {
        lock {
            stream<db:Type, persist:Error?> petTypesStream = self.dbClient->/types();
            return from db:Type pet_type in petTypesStream
                   select pet_type;
        }
    }

    isolated resource function post pettypes(db:TypeInsert petType) returns http:InternalServerError & readonly|TypeCreated|http:Conflict & readonly{
        lock {
            int[]|persist:Error result = self.dbClient->/types.post([petType]);
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return <TypeCreated> {
                body: {
                    insertedId: result[0]
                }
            };
        }
    }

    isolated resource function get pettypes/[int petTypeId]() returns db:Type | http:NotFound | http:InternalServerError | error {
        lock {
            db:Type|persist:Error result = self.dbClient->/types/[petTypeId]();
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function put pettypes/[int petTypeId](db:TypeUpdate petType) returns db:Type | http:NotFound | http:InternalServerError | error {
        lock {
            db:Type|persist:Error result = self.dbClient->/types/[petTypeId].put(petType);
            if result is persist:Error {
                if result is persist:NotFoundError {
                    return http:NOT_FOUND;
                }
                return http:INTERNAL_SERVER_ERROR;
            }
            return result;
        }
    }

    isolated resource function delete pettypes/[int petTypeId]() returns http:NoContent | http:InternalServerError {
        lock {
            db:Type|persist:Error result = self.dbClient->/types/[petTypeId].delete;
            if result is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
            return http:NO_CONTENT;
        }
    }
}
