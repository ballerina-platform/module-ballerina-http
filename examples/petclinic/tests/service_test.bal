import ballerina/http;
import ballerina/test;
import petclinic.db;

configurable int testPort = 9966;
final http:Client testClient = check new ("http://localhost:" + testPort.toString());

// Test data variables
int createdOwnerId = 0;
int createdPetId = 0;
int createdVisitId = 0;
int createdVetId = 0;
int createdSpecialtyId = 0;
int createdPetTypeId = 0;

// ===== Setup and Teardown =====

@test:BeforeSuite
function beforeSuiteFunc() {
    test:assertTrue(true, "Test suite initialized");
}

@test:AfterSuite
function afterSuiteFunc() {
    test:assertTrue(true, "Test suite completed");
}

// ===== Owner Endpoint Tests =====

@test:Config {
    groups: ["owner", "create"]
}
function testCreateOwner() returns error? {
    db:OwnerInsert owner = {
        firstName: "John",
        lastName: "Doe",
        address: "123 Main St",
        city: "Springfield",
        telephone: "1234567890"
    };

    http:Response response = check testClient->/petclinic/api/owners.post(owner);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdOwnerId = check payload.id;
    test:assertTrue(createdOwnerId > 0, "Owner ID should be greater than 0");
}

@test:Config {
    groups: ["owner", "create", "validation"],
    dependsOn: [testCreateOwner]
}
function testCreateOwnerWithEmptyFirstName() returns error? {
    db:OwnerInsert owner = {
        firstName: "",
        lastName: "Doe",
        address: "123 Main St",
        city: "Springfield",
        telephone: "1234567890"
    };

    http:Response response = check testClient->/petclinic/api/owners.post(owner);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.title, "Bad Request");
    test:assertEquals(payload.detail, "First name cannot be empty");
}

@test:Config {
    groups: ["owner", "create", "validation"],
    dependsOn: [testCreateOwner]
}
function testCreateOwnerWithInvalidTelephone() returns error? {
    db:OwnerInsert owner = {
        firstName: "Jane",
        lastName: "Doe",
        address: "123 Main St",
        city: "Springfield",
        telephone: "123"
    };

    http:Response response = check testClient->/petclinic/api/owners.post(owner);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.detail, "Telephone must be at least 10 digits");
}

@test:Config {
    groups: ["owner", "read"],
    dependsOn: [testCreateOwner]
}
function testGetOwnerById() returns error? {
    db:Owner owner = check testClient->/petclinic/api/owners/[createdOwnerId].get();
    test:assertEquals(owner.firstName, "John");
    test:assertEquals(owner.lastName, "Doe");
    test:assertEquals(owner.city, "Springfield");
}

@test:Config {
    groups: ["owner", "read"],
    dependsOn: [testCreateOwner]
}
function testGetOwnerByIdNotFound() returns error? {
    http:Response response = check testClient->/petclinic/api/owners/[999999].get();
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.title, "Not Found");
    string detail = check payload.detail;
    test:assertTrue(detail.includes("999999"));
}

@test:Config {
    groups: ["owner", "read"],
    dependsOn: [testCreateOwner]
}
function testGetAllOwners() returns error? {
    db:Owner[] owners = check testClient->/petclinic/api/owners.get();
    test:assertTrue(owners.length() > 0, "Should return at least one owner");
}

@test:Config {
    groups: ["owner", "read"],
    dependsOn: [testCreateOwner]
}
function testGetOwnersByLastName() returns error? {
    db:Owner[] owners = check testClient->/petclinic/api/owners.get(lastName = "Doe");
    test:assertTrue(owners.length() > 0, "Should return at least one owner with last name Doe");

    foreach db:Owner owner in owners {
        test:assertEquals(owner.lastName, "Doe");
    }
}

@test:Config {
    groups: ["owner", "update"],
    dependsOn: [testCreateOwner]
}
function testUpdateOwner() returns error? {
    db:OwnerUpdate ownerUpdate = {
        firstName: "Johnny",
        city: "New City"
    };

    db:Owner updatedOwner = check testClient->/petclinic/api/owners/[createdOwnerId].put(ownerUpdate);
    test:assertEquals(updatedOwner.firstName, "Johnny");
    test:assertEquals(updatedOwner.city, "New City");
    test:assertEquals(updatedOwner.lastName, "Doe"); // Should remain unchanged
}

@test:Config {
    groups: ["owner", "update"],
    dependsOn: [testCreateOwner]
}
function testUpdateOwnerNotFound() returns error? {
    db:OwnerUpdate ownerUpdate = {
        firstName: "Test"
    };

    http:Response response = check testClient->/petclinic/api/owners/[999999].put(ownerUpdate);
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);
}

// ===== Pet Type Endpoint Tests =====

@test:Config {
    groups: ["pettype", "create"]
}
function testCreatePetType() returns error? {
    db:TypeInsert petType = {
        name: "Dog"
    };

    http:Response response = check testClient->/petclinic/api/pettypes.post(petType);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdPetTypeId = check payload.id;
    test:assertTrue(createdPetTypeId > 0);
}

@test:Config {
    groups: ["pettype", "create", "validation"]
}
function testCreatePetTypeWithEmptyName() returns error? {
    db:TypeInsert petType = {
        name: "   "
    };

    http:Response response = check testClient->/petclinic/api/pettypes.post(petType);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.detail, "Pet type name cannot be empty");
}

@test:Config {
    groups: ["pettype", "read"],
    dependsOn: [testCreatePetType]
}
function testGetPetTypeById() returns error? {
    db:Type petType = check testClient->/petclinic/api/pettypes/[createdPetTypeId].get();
    test:assertEquals(petType.name, "Dog");
}

@test:Config {
    groups: ["pettype", "read"],
    dependsOn: [testCreatePetType]
}
function testGetAllPetTypes() returns error? {
    db:Type[] petTypes = check testClient->/petclinic/api/pettypes.get();
    test:assertTrue(petTypes.length() > 0);
}

@test:Config {
    groups: ["pettype", "update"],
    dependsOn: [testCreatePetType]
}
function testUpdatePetType() returns error? {
    db:TypeUpdate petTypeUpdate = {
        name: "Canine"
    };

    db:Type updatedPetType = check testClient->/petclinic/api/pettypes/[createdPetTypeId].put(petTypeUpdate);
    test:assertEquals(updatedPetType.name, "Canine");
}

// ===== Pet Endpoint Tests =====

@test:Config {
    groups: ["pet", "create"],
    dependsOn: [testCreateOwner, testCreatePetType]
}
function testCreatePet() returns error? {
    db:PetInsert pet = {
        name: "Buddy",
        birthDate: {year: 2020, month: 1, day: 15},
        typeId: createdPetTypeId,
        ownerId: createdOwnerId
    };

    http:Response response = check testClient->/petclinic/api/owners/[createdOwnerId]/pets.post(pet);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdPetId = check payload.id;
    test:assertTrue(createdPetId > 0);
}

@test:Config {
    groups: ["pet", "create", "validation"],
    dependsOn: [testCreateOwner, testCreatePetType]
}
function testCreatePetWithMismatchedOwnerId() returns error? {
    db:PetInsert pet = {
        name: "Max",
        birthDate: {year: 2021, month: 3, day: 10},
        typeId: createdPetTypeId,
        ownerId: 99999 // Different from path parameter
    };

    http:Response response = check testClient->/petclinic/api/owners/[createdOwnerId]/pets.post(pet);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    string detail = check payload.detail;
    test:assertTrue(detail.includes("does not match"));
}

@test:Config {
    groups: ["pet", "create"],
    dependsOn: [testCreatePetType]
}
function testCreatePetWithNonExistentOwner() returns error? {
    db:PetInsert pet = {
        name: "Charlie",
        birthDate: {year: 2019, month: 5, day: 20},
        typeId: createdPetTypeId,
        ownerId: 999999
    };

    http:Response response = check testClient->/petclinic/api/owners/[999999]/pets.post(pet);
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.title, "Not Found");
}

@test:Config {
    groups: ["pet", "read"],
    dependsOn: [testCreatePet]
}
function testGetPetById() returns error? {
    db:Pet pet = check testClient->/petclinic/api/pets/[createdPetId].get();
    test:assertEquals(pet.name, "Buddy");
    test:assertEquals(pet.ownerId, createdOwnerId);
}

@test:Config {
    groups: ["pet", "read"],
    dependsOn: [testCreatePet]
}
function testGetAllPets() returns error? {
    db:Pet[] pets = check testClient->/petclinic/api/pets.get();
    test:assertTrue(pets.length() > 0);
}

@test:Config {
    groups: ["pet", "update"],
    dependsOn: [testCreatePet]
}
function testUpdatePet() returns error? {
    db:PetUpdate petUpdate = {
        name: "Buddy Jr."
    };

    db:Pet updatedPet = check testClient->/petclinic/api/pets/[createdPetId].put(petUpdate);
    test:assertEquals(updatedPet.name, "Buddy Jr.");
}

// ===== Visit Endpoint Tests =====

@test:Config {
    groups: ["visit", "create"],
    dependsOn: [testCreatePet]
}
function testCreateVisit() returns error? {
    db:VisitInsert visit = {
        visitDate: {year: 2024, month: 1, day: 15},
        description: "Annual checkup",
        petId: createdPetId
    };

    http:Response response = check testClient->/petclinic/api/owners/[createdOwnerId]/pets/[createdPetId]/visits.post(visit);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdVisitId = check payload.id;
    test:assertTrue(createdVisitId > 0);
}

@test:Config {
    groups: ["visit", "create", "validation"],
    dependsOn: [testCreatePet]
}
function testCreateVisitWithMismatchedPetId() returns error? {
    db:VisitInsert visit = {
        visitDate: {year: 2024, month: 2, day: 1},
        description: "Vaccination",
        petId: 99999 // Different from path parameter
    };

    http:Response response = check testClient->/petclinic/api/owners/[createdOwnerId]/pets/[createdPetId]/visits.post(visit);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    string detail = check payload.detail;
    test:assertTrue(detail.includes("does not match"));
}

@test:Config {
    groups: ["visit", "create"],
    dependsOn: [testCreatePet]
}
function testCreateVisitWithWrongOwner() returns error? {
    db:VisitInsert visit = {
        visitDate: {year: 2024, month: 3, day: 1},
        description: "Emergency visit",
        petId: createdPetId
    };

    http:Response response = check testClient->/petclinic/api/owners/[999999]/pets/[createdPetId]/visits.post(visit);
    test:assertEquals(response.statusCode, http:STATUS_CONFLICT);

    json payload = check response.getJsonPayload();
    string detail = check payload.detail;
    test:assertTrue(detail.includes("does not belong"));
}

@test:Config {
    groups: ["visit", "read"],
    dependsOn: [testCreateVisit]
}
function testGetVisitById() returns error? {
    db:Visit visit = check testClient->/petclinic/api/visits/[createdVisitId].get();
    test:assertEquals(visit.description, "Annual checkup");
    test:assertEquals(visit.petId, createdPetId);
}

@test:Config {
    groups: ["visit", "update"],
    dependsOn: [testCreateVisit]
}
function testUpdateVisit() returns error? {
    db:VisitUpdate visitUpdate = {
        description: "Annual checkup - completed"
    };

    db:Visit updatedVisit = check testClient->/petclinic/api/visits/[createdVisitId].put(visitUpdate);
    test:assertEquals(updatedVisit.description, "Annual checkup - completed");
}

// ===== Vet Endpoint Tests =====

@test:Config {
    groups: ["vet", "create"]
}
function testCreateVet() returns error? {
    db:VetInsert vet = {
        firstName: "James",
        lastName: "Carter"
    };

    http:Response response = check testClient->/petclinic/api/vets.post(vet);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdVetId = check payload.id;
    test:assertTrue(createdVetId > 0);
}

@test:Config {
    groups: ["vet", "create", "validation"]
}
function testCreateVetWithEmptyFirstName() returns error? {
    db:VetInsert vet = {
        firstName: "",
        lastName: "Smith"
    };

    http:Response response = check testClient->/petclinic/api/vets.post(vet);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.detail, "First name cannot be empty");
}

@test:Config {
    groups: ["vet", "read"],
    dependsOn: [testCreateVet]
}
function testGetVetById() returns error? {
    db:Vet vet = check testClient->/petclinic/api/vets/[createdVetId].get();
    test:assertEquals(vet.firstName, "James");
    test:assertEquals(vet.lastName, "Carter");
}

@test:Config {
    groups: ["vet", "read"],
    dependsOn: [testCreateVet]
}
function testGetAllVets() returns error? {
    db:Vet[] vets = check testClient->/petclinic/api/vets.get();
    test:assertTrue(vets.length() > 0);
}

@test:Config {
    groups: ["vet", "update"],
    dependsOn: [testCreateVet]
}
function testUpdateVet() returns error? {
    db:VetUpdate vetUpdate = {
        firstName: "Dr. James"
    };

    db:Vet updatedVet = check testClient->/petclinic/api/vets/[createdVetId].put(vetUpdate);
    test:assertEquals(updatedVet.firstName, "Dr. James");
    test:assertEquals(updatedVet.lastName, "Carter");
}

// ===== Specialty Endpoint Tests =====

@test:Config {
    groups: ["specialty", "create"]
}
function testCreateSpecialty() returns error? {
    db:SpecialtyInsert specialty = {
        name: "Radiology"
    };

    http:Response response = check testClient->/petclinic/api/specialties.post(specialty);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    json payload = check response.getJsonPayload();
    createdSpecialtyId = check payload.id;
    test:assertTrue(createdSpecialtyId > 0);
}

@test:Config {
    groups: ["specialty", "create", "validation"]
}
function testCreateSpecialtyWithEmptyName() returns error? {
    db:SpecialtyInsert specialty = {
        name: "  "
    };

    http:Response response = check testClient->/petclinic/api/specialties.post(specialty);
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);

    json payload = check response.getJsonPayload();
    test:assertEquals(payload.detail, "Specialty name cannot be empty");
}

@test:Config {
    groups: ["specialty", "read"],
    dependsOn: [testCreateSpecialty]
}
function testGetSpecialtyById() returns error? {
    db:Specialty specialty = check testClient->/petclinic/api/specialties/[createdSpecialtyId].get();
    test:assertEquals(specialty.name, "Radiology");
}

@test:Config {
    groups: ["specialty", "read"],
    dependsOn: [testCreateSpecialty]
}
function testGetAllSpecialties() returns error? {
    db:Specialty[] specialties = check testClient->/petclinic/api/specialties.get();
    test:assertTrue(specialties.length() > 0);
}

@test:Config {
    groups: ["specialty", "update"],
    dependsOn: [testCreateSpecialty]
}
function testUpdateSpecialty() returns error? {
    db:SpecialtyUpdate specialtyUpdate = {
        name: "Advanced Radiology"
    };

    db:Specialty updatedSpecialty = check testClient->/petclinic/api/specialties/[createdSpecialtyId].put(specialtyUpdate);
    test:assertEquals(updatedSpecialty.name, "Advanced Radiology");
}

// ===== Vet Specialty Endpoint Tests =====

@test:Config {
    groups: ["vetspecialty", "create"],
    dependsOn: [testCreateVet, testCreateSpecialty]
}
function testCreateVetSpecialty() returns error? {
    db:VetSpecialtyInsert vetSpecialty = {
        vetId: createdVetId,
        specialtyId: createdSpecialtyId
    };

    http:Response response = check testClient->/petclinic/api/vetspecialties.post(vetSpecialty);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);
}

@test:Config {
    groups: ["vetspecialty", "read"],
    dependsOn: [testCreateVetSpecialty]
}
function testGetVetSpecialties() returns error? {
    db:VetSpecialty[] vetSpecialties = check testClient->/petclinic/api/vetspecialties/[createdVetId].get();
    test:assertTrue(vetSpecialties.length() > 0);

    boolean found = false;
    foreach db:VetSpecialty vs in vetSpecialties {
        if vs.vetId == createdVetId && vs.specialtyId == createdSpecialtyId {
            found = true;
            break;
        }
    }
    test:assertTrue(found, "Created vet specialty should be present");
}

@test:Config {
    groups: ["vetspecialty", "delete"],
    dependsOn: [testCreateVetSpecialty, testGetVetSpecialties]
}
function testDeleteVetSpecialty() returns error? {
    http:Response response = check testClient->/petclinic/api/vetspecialties/[createdVetId]/[createdSpecialtyId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);

    // Verify deletion
    db:VetSpecialty[] vetSpecialties = check testClient->/petclinic/api/vetspecialties/[createdVetId].get();

    boolean found = false;
    foreach db:VetSpecialty vs in vetSpecialties {
        if vs.vetId == createdVetId && vs.specialtyId == createdSpecialtyId {
            found = true;
            break;
        }
    }
    test:assertFalse(found, "Deleted vet specialty should not be present");
}

// ===== Cleanup Tests (Run at the end) =====

@test:Config {
    groups: ["cleanup"],
    dependsOn: [testDeleteVetSpecialty]
}
function testDeleteVisit() returns error? {
    http:Response response = check testClient->/petclinic/api/visits/[createdVisitId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}

@test:Config {
    groups: ["cleanup"],
    dependsOn: [testDeleteVisit]
}
function testDeletePet() returns error? {
    http:Response response = check testClient->/petclinic/api/pets/[createdPetId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}

@test:Config {
    groups: ["cleanup"],
    dependsOn: [testDeletePet]
}
function testDeleteOwner() returns error? {
    http:Response response = check testClient->/petclinic/api/owners/[createdOwnerId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}

@test:Config {
    groups: ["cleanup"],
    dependsOn: [testDeleteVetSpecialty]
}
function testDeleteVet() returns error? {
    http:Response response = check testClient->/petclinic/api/vets/[createdVetId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}

@test:Config {
    groups: ["cleanup"]
}
function testDeleteSpecialty() returns error? {
    http:Response response = check testClient->/petclinic/api/specialties/[createdSpecialtyId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}

@test:Config {
    groups: ["cleanup"]
}
function testDeletePetType() returns error? {
    http:Response response = check testClient->/petclinic/api/pettypes/[createdPetTypeId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);
}
