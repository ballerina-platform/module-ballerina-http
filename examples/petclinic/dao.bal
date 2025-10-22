import ballerina/sql;

# Owner DAO operations
#
# + lastName - last name of the owner. Optional parameter
# + return - A list of owners
public function getAllOwners(string? lastName = ()) returns Owner[]|error {
    sql:ParameterizedQuery query;
    if lastName is string {
        query = `SELECT o.id, o.first_name, o.last_name, o.address, o.city, o.telephone 
                 FROM owners o WHERE o.last_name ILIKE %${lastName}%`;
    } else {
        query = `SELECT o.id, o.first_name, o.last_name, o.address, o.city, o.telephone FROM owners o`;
    }
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Owner[] owners = [];
    
    check from record {} result in resultStream
        do {
            Owner owner = {
                id: <int>result["id"],
                firstName: <string>result["first_name"],
                lastName: <string>result["last_name"],
                address: <string>result["address"],
                city: <string>result["city"],
                telephone: <string>result["telephone"],
                pets: check getPetsByOwnerId(<int>result["id"])
            };
            owners.push(owner);
        };
    
    return owners;
}

# Get Owner By ID
#
# + ownerId - Owner id
# + return - return Owner
public function getOwnerById(int ownerId) returns Owner|error? {
    sql:ParameterizedQuery query = `SELECT o.id, o.first_name, o.last_name, o.address, o.city, o.telephone 
                                   FROM owners o WHERE o.id = ${ownerId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        firstName: <string>result["first_name"],
        lastName: <string>result["last_name"],
        address: <string>result["address"],
        city: <string>result["city"],
        telephone: <string>result["telephone"],
        pets: check getPetsByOwnerId(<int>result["id"])
    };
}

public function createOwner(OwnerFields ownerFields) returns Owner|error {
    sql:ParameterizedQuery query = `INSERT INTO owners (first_name, last_name, address, city, telephone) 
                                   VALUES (${ownerFields.firstName}, ${ownerFields.lastName}, 
                                          ${ownerFields.address}, ${ownerFields.city}, ${ownerFields.telephone}) 
                                   RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        Owner? owner = check getOwnerById(generatedId);
        if owner is Owner {
            return owner;
        }
    }
    return error("Failed to create owner");
}

public function updateOwner(int ownerId, OwnerFields ownerFields) returns Owner|error? {
    sql:ParameterizedQuery query = `UPDATE owners SET first_name = ${ownerFields.firstName}, 
                                   last_name = ${ownerFields.lastName}, address = ${ownerFields.address}, 
                                   city = ${ownerFields.city}, telephone = ${ownerFields.telephone} 
                                   WHERE id = ${ownerId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        return check getOwnerById(ownerId);
    }
    return ();
}

public function deleteOwner(int ownerId) returns Owner|error? {
    Owner? owner = check getOwnerById(ownerId);
    if owner is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM owners WHERE id = ${ownerId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return owner;
    }
    return ();
}

// Pet DAO operations
public function getAllPets() returns Pet[]|error {
    sql:ParameterizedQuery query = `SELECT p.id, p.name, p.birth_date, p.owner_id, 
                                   pt.id as type_id, pt.name as type_name 
                                   FROM pets p 
                                   JOIN pet_types pt ON p.type_id = pt.id`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Pet[] pets = [];
    
    check from record {} result in resultStream
        do {
            Pet pet = {
                id: <int>result["id"],
                name: <string>result["name"],
                birthDate: <string>result["birth_date"],
                ownerId: <int>result["owner_id"],
                'type: {
                    id: <int>result["type_id"],
                    name: <string>result["type_name"]
                },
                visits: check getVisitsByPetId(<int>result["id"])
            };
            pets.push(pet);
        };
    
    return pets;
}

public function getPetById(int petId) returns Pet|error? {
    sql:ParameterizedQuery query = `SELECT p.id, p.name, p.birth_date, p.owner_id, 
                                   pt.id as type_id, pt.name as type_name 
                                   FROM pets p 
                                   JOIN pet_types pt ON p.type_id = pt.id 
                                   WHERE p.id = ${petId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        name: <string>result["name"],
        birthDate: <string>result["birth_date"],
        ownerId: <int>result["owner_id"],
        'type: {
            id: <int>result["type_id"],
            name: <string>result["type_name"]
        },
        visits: check getVisitsByPetId(<int>result["id"])
    };
}

public function getPetsByOwnerId(int ownerId) returns Pet[]|error {
    sql:ParameterizedQuery query = `SELECT p.id, p.name, p.birth_date, p.owner_id, 
                                   pt.id as type_id, pt.name as type_name 
                                   FROM pets p 
                                   JOIN pet_types pt ON p.type_id = pt.id 
                                   WHERE p.owner_id = ${ownerId}`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Pet[] pets = [];
    
    check from record {} result in resultStream
        do {
            Pet pet = {
                id: <int>result["id"],
                name: <string>result["name"],
                birthDate: <string>result["birth_date"],
                ownerId: <int>result["owner_id"],
                'type: {
                    id: <int>result["type_id"],
                    name: <string>result["type_name"]
                },
                visits: check getVisitsByPetId(<int>result["id"])
            };
            pets.push(pet);
        };
    
    return pets;
}

public function createPet(int ownerId, PetFields petFields) returns Pet|error {
    sql:ParameterizedQuery query = `INSERT INTO pets (name, birth_date, type_id, owner_id) 
                                   VALUES (${petFields.name}, ${petFields.birthDate}, 
                                          ${petFields.'type.id}, ${ownerId}) 
                                   RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        Pet? pet = check getPetById(generatedId);
        if pet is Pet {
            return pet;
        }
    }
    return error("Failed to create pet");
}

public function updatePet(int petId, Pet pet) returns Pet|error? {
    sql:ParameterizedQuery query = `UPDATE pets SET name = ${pet.name}, birth_date = ${pet.birthDate}, 
                                   type_id = ${pet.'type.id} WHERE id = ${petId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        return check getPetById(petId);
    }
    return ();
}

public function deletePet(int petId) returns Pet|error? {
    Pet? pet = check getPetById(petId);
    if pet is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM pets WHERE id = ${petId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return pet;
    }
    return ();
}

// Visit DAO operations
public function getVisitById(int visitId) returns Visit|error? {
    sql:ParameterizedQuery query = `SELECT id, visit_date, description, pet_id FROM visits WHERE id = ${visitId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        date: result["visit_date"] is () ? () : <string>result["visit_date"],
        description: <string>result["description"],
        petId: <int>result["pet_id"]
    };
}

public function getVisitsByPetId(int petId) returns Visit[]|error {
    sql:ParameterizedQuery query = `SELECT id, visit_date, description, pet_id FROM visits WHERE pet_id = ${petId}`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Visit[] visits = [];
    
    check from record {} result in resultStream
        do {
            Visit visit = {
                id: <int>result["id"],
                date: result["visit_date"] is () ? () : <string>result["visit_date"],
                description: <string>result["description"],
                petId: <int>result["pet_id"]
            };
            visits.push(visit);
        };
    
    return visits;
}

public function createVisit(int ownerId, int petId, VisitFields visitFields) returns Visit|error {
    sql:ParameterizedQuery query = `INSERT INTO visits (visit_date, description, pet_id) 
                                   VALUES (${visitFields.date}, ${visitFields.description}, ${petId}) 
                                   RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        Visit? visit = check getVisitById(generatedId);
        if visit is Visit {
            return visit;
        }
    }
    return error("Failed to create visit");
}

public function updateVisit(int visitId, VisitFields visitFields) returns Visit|error? {
    sql:ParameterizedQuery query = `UPDATE visits SET visit_date = ${visitFields.date}, 
                                   description = ${visitFields.description} WHERE id = ${visitId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        return check getVisitById(visitId);
    }
    return ();
}

public function deleteVisit(int visitId) returns Visit|error? {
    Visit? visit = check getVisitById(visitId);
    if visit is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM visits WHERE id = ${visitId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return visit;
    }
    return ();
}

// Vet DAO operations
public function getAllVets() returns Vet[]|error {
    sql:ParameterizedQuery query = `SELECT id, first_name, last_name FROM vets`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Vet[] vets = [];
    
    check from record {} result in resultStream
        do {
            Vet vet = {
                id: <int>result["id"],
                firstName: <string>result["first_name"],
                lastName: <string>result["last_name"],
                specialties: check getSpecialtiesByVetId(<int>result["id"])
            };
            vets.push(vet);
        };
    
    return vets;
}

public function getVetById(int vetId) returns Vet|error? {
    sql:ParameterizedQuery query = `SELECT id, first_name, last_name FROM vets WHERE id = ${vetId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        firstName: <string>result["first_name"],
        lastName: <string>result["last_name"],
        specialties: check getSpecialtiesByVetId(<int>result["id"])
    };
}

public function createVet(Vet vet) returns Vet|error {
    sql:ParameterizedQuery query = `INSERT INTO vets (first_name, last_name) 
                                   VALUES (${vet.firstName}, ${vet.lastName}) RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        // Insert specialties
        foreach Specialty specialty in vet.specialties {
            _ = check dbClient->execute(`INSERT INTO vet_specialties (vet_id, specialty_id) 
                                       VALUES (${generatedId}, ${specialty.id})`);
        }
        
        Vet? createdVet = check getVetById(generatedId);
        if createdVet is Vet {
            return createdVet;
        }
    }
    return error("Failed to create vet");
}

public function updateVet(int vetId, Vet vet) returns Vet|error? {
    sql:ParameterizedQuery query = `UPDATE vets SET first_name = ${vet.firstName}, 
                                   last_name = ${vet.lastName} WHERE id = ${vetId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        // Update specialties
        _ = check dbClient->execute(`DELETE FROM vet_specialties WHERE vet_id = ${vetId}`);
        foreach Specialty specialty in vet.specialties {
            _ = check dbClient->execute(`INSERT INTO vet_specialties (vet_id, specialty_id) 
                                       VALUES (${vetId}, ${specialty.id})`);
        }
        return check getVetById(vetId);
    }
    return ();
}

public function deleteVet(int vetId) returns Vet|error? {
    Vet? vet = check getVetById(vetId);
    if vet is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM vets WHERE id = ${vetId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return vet;
    }
    return ();
}

// Specialty DAO operations
public function getAllSpecialties() returns Specialty[]|error {
    sql:ParameterizedQuery query = `SELECT id, name FROM specialties`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Specialty[] specialties = [];
    
    check from record {} result in resultStream
        do {
            Specialty specialty = {
                id: <int>result["id"],
                name: <string>result["name"]
            };
            specialties.push(specialty);
        };
    
    return specialties;
}

public function getSpecialtyById(int specialtyId) returns Specialty|error? {
    sql:ParameterizedQuery query = `SELECT id, name FROM specialties WHERE id = ${specialtyId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        name: <string>result["name"]
    };
}

public function getSpecialtiesByVetId(int vetId) returns Specialty[]|error {
    sql:ParameterizedQuery query = `SELECT s.id, s.name FROM specialties s 
                                   JOIN vet_specialties vs ON s.id = vs.specialty_id 
                                   WHERE vs.vet_id = ${vetId}`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    Specialty[] specialties = [];
    
    check from record {} result in resultStream
        do {
            Specialty specialty = {
                id: <int>result["id"],
                name: <string>result["name"]
            };
            specialties.push(specialty);
        };
    
    return specialties;
}

public function createSpecialty(Specialty specialty) returns Specialty|error {
    sql:ParameterizedQuery query = `INSERT INTO specialties (name) VALUES (${specialty.name}) RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        Specialty? createdSpecialty = check getSpecialtyById(generatedId);
        if createdSpecialty is Specialty {
            return createdSpecialty;
        }
    }
    return error("Failed to create specialty");
}

public function updateSpecialty(int specialtyId, Specialty specialty) returns Specialty|error? {
    sql:ParameterizedQuery query = `UPDATE specialties SET name = ${specialty.name} WHERE id = ${specialtyId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        return check getSpecialtyById(specialtyId);
    }
    return ();
}

public function deleteSpecialty(int specialtyId) returns Specialty|error? {
    Specialty? specialty = check getSpecialtyById(specialtyId);
    if specialty is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM specialties WHERE id = ${specialtyId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return specialty;
    }
    return ();
}

// Pet Type DAO operations
public function getAllPetTypes() returns PetType[]|error {
    sql:ParameterizedQuery query = `SELECT id, name FROM pet_types`;
    
    stream<record {}, error?> resultStream = dbClient->query(query);
    PetType[] petTypes = [];
    
    check from record {} result in resultStream
        do {
            PetType petType = {
                id: <int>result["id"],
                name: <string>result["name"]
            };
            petTypes.push(petType);
        };
    
    return petTypes;
}

public function getPetTypeById(int petTypeId) returns PetType|error? {
    sql:ParameterizedQuery query = `SELECT id, name FROM pet_types WHERE id = ${petTypeId}`;
    
    record {}? result = check dbClient->queryRow(query);
    if result is () {
        return ();
    }
    
    return {
        id: <int>result["id"],
        name: <string>result["name"]
    };
}

public function createPetType(PetTypeFields petTypeFields) returns PetType|error {
    sql:ParameterizedQuery query = `INSERT INTO pet_types (name) VALUES (${petTypeFields.name}) RETURNING id`;
    
    int|string? generatedId = check dbClient->queryRow(query);
    if generatedId is int {
        PetType? createdPetType = check getPetTypeById(generatedId);
        if createdPetType is PetType {
            return createdPetType;
        }
    }
    return error("Failed to create pet type");
}

public function updatePetType(int petTypeId, PetType petType) returns PetType|error? {
    sql:ParameterizedQuery query = `UPDATE pet_types SET name = ${petType.name} WHERE id = ${petTypeId}`;
    
    sql:ExecutionResult result = check dbClient->execute(query);
    if result.affectedRowCount > 0 {
        return check getPetTypeById(petTypeId);
    }
    return ();
}

public function deletePetType(int petTypeId) returns PetType|error? {
    PetType? petType = check getPetTypeById(petTypeId);
    if petType is () {
        return ();
    }
    
    sql:ParameterizedQuery query = `DELETE FROM pet_types WHERE id = ${petTypeId}`;
    sql:ExecutionResult result = check dbClient->execute(query);
    
    if result.affectedRowCount > 0 {
        return petType;
    }
    return ();
}
