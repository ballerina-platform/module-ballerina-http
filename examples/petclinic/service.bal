import petclinic.db;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import ballerina/sql;

configurable int port = 9966;

// Pet Clinic REST API Service
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
        log:printInfo("Pet Clinic API started successfully");
    }

    // Owner endpoints
    isolated resource function get owners(string? lastName = ()) returns db:Owner[]|InternalServerError {
        sql:ParameterizedQuery whereClause =
            lastName is string
            ? `last_name = ${lastName}`
            : ``;

        stream<db:Owner, persist:Error?> ownersStream =
                self.dbClient->/owners.get(whereClause = whereClause);

        db:Owner[]|error owners = from db:Owner owner in ownersStream
            select owner;
        
        if owners is error {
            log:printError("Failed to retrieve owners", owners);
            return <InternalServerError>{
                body: {
                    message: "Failed to retrieve owners",
                    'error: owners.message()
                }
            };
        }
        return owners;
    }

    isolated resource function post owners(db:OwnerInsert owner) returns InternalServerError|OwnerCreated {
        int[]|persist:Error result = self.dbClient->/owners.post([owner]);
        if result is persist:Error {
            log:printError("Failed to create owner", result);
            return <InternalServerError>{
                body: {
                    message: "Failed to create owner",
                    'error: result.message()
                }
            };
        }
        return <OwnerCreated>{
            body: {
                insertedId: result[0]
            }
        };
    }

    isolated resource function get owners/[int ownerId]() returns InternalServerError|http:NotFound|db:Owner {
        db:Owner|persist:Error result = self.dbClient->/owners/[ownerId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve owner", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve owner with ID ${ownerId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put owners/[int ownerId](db:OwnerUpdate owner) returns InternalServerError|http:NotFound|db:Owner {
        db:Owner|persist:Error result = self.dbClient->/owners/[ownerId].put(owner);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update owner", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update owner with ID ${ownerId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete owners/[int ownerId]() returns http:NoContent|InternalServerError {
        db:Owner|persist:Error result = self.dbClient->/owners/[ownerId].delete();
        if result is persist:Error {
            log:printError("Failed to delete owner", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete owner with ID ${ownerId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Pet endpoints for owners
    isolated resource function post owners/[int ownerId]/pets(db:PetInsert pet) returns InternalServerError|OwnerNotFound|PetCreated {
        db:Owner|persist:Error result = self.dbClient->/owners/[ownerId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return <OwnerNotFound>{
                    body: {
                        message: string `Owner ${ownerId} not found`
                    }
                };
            }
            log:printError("Failed to verify owner", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to verify owner with ID ${ownerId}`,
                    'error: result.message()
                }
            };
        }

        int[]|persist:Error petInsertResult = self.dbClient->/pets.post([pet]);
        if petInsertResult is persist:Error {
            log:printError("Failed to create pet", petInsertResult);
            return <InternalServerError>{
                body: {
                    message: string `Failed to create pet for owner ${ownerId}`,
                    'error: petInsertResult.message()
                }
            };
        }
        return <PetCreated>{
            body: {
                insertedId: petInsertResult[0]
            }
        };
    }

    // Visit endpoints for owners and pets
    isolated resource function post owners/[int ownerId]/pets/[int petId]/visits(db:VisitInsert visit) returns http:Conflict|InternalServerError|PetNotFound|VisitCreated {
        db:Pet|persist:Error pet = self.dbClient->/pets/[petId]();
        if pet is persist:Error {
            if pet is persist:NotFoundError {
                return <PetNotFound>{
                    body: {
                        message: string `Pet ${petId} not found`
                    }
                };
            }
            log:printError("Failed to retrieve pet", pet);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve pet with ID ${petId}`,
                    'error: pet.message()
                }
            };
        }

        if (pet.ownerId != ownerId) {
            return <http:Conflict>{
                body: "Pet not found for this owner"
            };
        }

        int[]|persist:Error visitInsertResult = self.dbClient->/visits.post([visit]);
        if visitInsertResult is persist:Error {
            log:printError("Failed to create visit", visitInsertResult);
            return <InternalServerError>{
                body: {
                    message: string `Failed to create visit for pet ${petId}`,
                    'error: visitInsertResult.message()
                }
            };
        }
        return <VisitCreated>{
            body: {
                insertedId: visitInsertResult[0]
            }
        };
    }

    // Pet endpoints
    isolated resource function get pets() returns db:Pet[]|InternalServerError {
        stream<db:Pet, persist:Error?> petsStream = self.dbClient->/pets.get();
        db:Pet[]|error pets = from db:Pet pet in petsStream
            select pet;
        
        if pets is error {
            log:printError("Failed to retrieve pets", pets);
            return <InternalServerError>{
                body: {
                    message: "Failed to retrieve pets",
                    'error: pets.message()
                }
            };
        }
        return pets;
    }

    isolated resource function get pets/[int petId]() returns db:Pet|http:NotFound|InternalServerError {
        db:Pet|persist:Error result = self.dbClient->/pets/[petId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve pet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve pet with ID ${petId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put pets/[int petId](db:PetUpdate pet) returns db:Pet|http:NotFound|InternalServerError {
        db:Pet|persist:Error result = self.dbClient->/pets/[petId].put(pet);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update pet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update pet with ID ${petId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete pets/[int petId]() returns http:NoContent|InternalServerError {
        db:Pet|persist:Error result = self.dbClient->/pets/[petId].delete();
        if result is persist:Error {
            log:printError("Failed to delete pet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete pet with ID ${petId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Visit endpoints
    isolated resource function get visits/[int visitId]() returns db:Visit|http:NotFound|InternalServerError {
        db:Visit|persist:Error result = self.dbClient->/visits/[visitId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve visit", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve visit with ID ${visitId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put visits/[int visitId](db:VisitUpdate visit) returns db:Visit|http:NotFound|InternalServerError {
        db:Visit|persist:Error result = self.dbClient->/visits/[visitId].put(visit);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update visit", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update visit with ID ${visitId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete visits/[int visitId]() returns http:NoContent|InternalServerError {
        db:Visit|persist:Error result = self.dbClient->/visits/[visitId].delete();
        if result is persist:Error {
            log:printError("Failed to delete visit", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete visit with ID ${visitId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Vet endpoints
    isolated resource function get vets() returns db:Vet[]|InternalServerError {
        stream<db:Vet, persist:Error?> vetsStream = self.dbClient->/vets();
        db:Vet[]|error vets = from db:Vet vet in vetsStream
            select vet;
        
        if vets is error {
            log:printError("Failed to retrieve vets", vets);
            return <InternalServerError>{
                body: {
                    message: "Failed to retrieve vets",
                    'error: vets.message()
                }
            };
        }
        return vets;
    }

    isolated resource function post vets(db:VetInsert vet) returns InternalServerError|VetCreated {
        int[]|persist:Error result = self.dbClient->/vets.post([vet]);
        if result is persist:Error {
            log:printError("Failed to create vet", result);
            return <InternalServerError>{
                body: {
                    message: "Failed to create vet",
                    'error: result.message()
                }
            };
        }
        return <VetCreated>{
            body: {
                insertedId: result[0]
            }
        };
    }

    isolated resource function get vets/[int vetId]() returns db:Vet|http:NotFound|InternalServerError {
        db:Vet|persist:Error result = self.dbClient->/vets/[vetId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve vet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve vet with ID ${vetId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put vets/[int vetId](db:VetUpdate vet) returns db:Vet|http:NotFound|InternalServerError {
        db:Vet|persist:Error result = self.dbClient->/vets/[vetId].put(vet);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update vet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update vet with ID ${vetId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete vets/[int vetId]() returns http:NoContent|InternalServerError {
        db:Vet|persist:Error result = self.dbClient->/vets/[vetId].delete();
        if result is persist:Error {
            log:printError("Failed to delete vet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete vet with ID ${vetId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Specialty endpoints
    isolated resource function get specialties() returns db:Specialty[]|InternalServerError {
        stream<db:Specialty, persist:Error?> specialtyStream = self.dbClient->/specialties();
        db:Specialty[]|error specialties = from db:Specialty specialty in specialtyStream
            select specialty;
        
        if specialties is error {
            log:printError("Failed to retrieve specialties", specialties);
            return <InternalServerError>{
                body: {
                    message: "Failed to retrieve specialties",
                    'error: specialties.message()
                }
            };
        }
        return specialties;
    }

    isolated resource function post specialties(db:SpecialtyInsert specialty) returns InternalServerError|SpecialtyCreated {
        int[]|persist:Error result = self.dbClient->/specialties.post([specialty]);
        if result is persist:Error {
            log:printError("Failed to create specialty", result);
            return <InternalServerError>{
                body: {
                    message: "Failed to create specialty",
                    'error: result.message()
                }
            };
        }
        return <SpecialtyCreated>{
            body: {
                insertedId: result[0]
            }
        };
    }

    isolated resource function get specialties/[int specialtyId]() returns db:Specialty|http:NotFound|InternalServerError {
        db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve specialty", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve specialty with ID ${specialtyId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put specialties/[int specialtyId](db:SpecialtyUpdate specialty) returns db:Specialty|http:NotFound|InternalServerError {
        db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId].put(specialty);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update specialty", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update specialty with ID ${specialtyId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete specialties/[int specialtyId]() returns http:NoContent|InternalServerError {
        db:Specialty|persist:Error result = self.dbClient->/specialties/[specialtyId].delete();
        if result is persist:Error {
            log:printError("Failed to delete specialty", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete specialty with ID ${specialtyId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Vet Speciality endpoints
    isolated resource function get vetspecialties/[int vetId]() returns db:VetSpecialty[]|http:NotFound|InternalServerError {
        db:Vet|persist:Error result = self.dbClient->/vets/[vetId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return <http:NotFound>{
                    body: string `Vet ${vetId} not found`
                };
            }
            log:printError("Failed to verify vet", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to verify vet with ID ${vetId}`,
                    'error: result.message()
                }
            };
        }

        sql:ParameterizedQuery whereClause = `vet_id = ${vetId}`;

        stream<db:VetSpecialty, persist:Error?> vetSpecialtyStream =
                self.dbClient->/vetspecialties.get(whereClause = whereClause);

        db:VetSpecialty[]|error vetSpecialties = from db:VetSpecialty vs in vetSpecialtyStream
            select vs;
        
        if vetSpecialties is error {
            log:printError("Failed to retrieve vet specialties", vetSpecialties);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve specialties for vet ${vetId}`,
                    'error: vetSpecialties.message()
                }
            };
        }
        return vetSpecialties;
    }

    isolated resource function post vetspecialties(db:VetSpecialtyInsert vetSpecialty) returns InternalServerError|SpecialtyCreated {
        int[][]|persist:Error result = self.dbClient->/vetspecialties.post([vetSpecialty]);
        if result is persist:Error {
            log:printError("Failed to create vet specialty", result);
            return <InternalServerError>{
                body: {
                    message: "Failed to create vet specialty",
                    'error: result.message()
                }
            };
        }
        return <SpecialtyCreated>{
            body: {
                insertedId: result
            }
        };
    }

    isolated resource function delete vetspecialties/[int vetId]/[int specialtyId]() returns http:NoContent|InternalServerError {
        db:VetSpecialty|persist:Error result = self.dbClient->/vetspecialties/[vetId]/[specialtyId].delete();
        if result is persist:Error {
            log:printError("Failed to delete vet specialty", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete specialty ${specialtyId} for vet ${vetId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }

    // Pet Type endpoints
    isolated resource function get pettypes() returns db:Type[]|InternalServerError {
        stream<db:Type, persist:Error?> petTypesStream = self.dbClient->/types();
        db:Type[]|error petTypes = from db:Type pet_type in petTypesStream
            select pet_type;
        
        if petTypes is error {
            log:printError("Failed to retrieve pet types", petTypes);
            return <InternalServerError>{
                body: {
                    message: "Failed to retrieve pet types",
                    'error: petTypes.message()
                }
            };
        }
        return petTypes;
    }

    isolated resource function post pettypes(db:TypeInsert petType) returns InternalServerError|TypeCreated {
        int[]|persist:Error result = self.dbClient->/types.post([petType]);
        if result is persist:Error {
            log:printError("Failed to create pet type", result);
            return <InternalServerError>{
                body: {
                    message: "Failed to create pet type",
                    'error: result.message()
                }
            };
        }
        return <TypeCreated>{
            body: {
                insertedId: result[0]
            }
        };
    }

    isolated resource function get pettypes/[int petTypeId]() returns db:Type|http:NotFound|InternalServerError {
        db:Type|persist:Error result = self.dbClient->/types/[petTypeId]();
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to retrieve pet type", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to retrieve pet type with ID ${petTypeId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function put pettypes/[int petTypeId](db:TypeUpdate petType) returns db:Type|http:NotFound|InternalServerError {
        db:Type|persist:Error result = self.dbClient->/types/[petTypeId].put(petType);
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            log:printError("Failed to update pet type", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to update pet type with ID ${petTypeId}`,
                    'error: result.message()
                }
            };
        }
        return result;
    }

    isolated resource function delete pettypes/[int petTypeId]() returns http:NoContent|InternalServerError {
        db:Type|persist:Error result = self.dbClient->/types/[petTypeId].delete();
        if result is persist:Error {
            log:printError("Failed to delete pet type", result);
            return <InternalServerError>{
                body: {
                    message: string `Failed to delete pet type with ID ${petTypeId}`,
                    'error: result.message()
                }
            };
        }
        return http:NO_CONTENT;
    }
}