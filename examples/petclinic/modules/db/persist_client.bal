// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/persist.sql as psql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

const SPECIALTY = "specialties";
const OWNER = "owners";
const TYPE = "types";
const VET_SPECIALTY = "vetspecialties";
const VET = "vets";
const VISIT = "visits";
const PET = "pets";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final postgresql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} metadata = {
        [SPECIALTY]: {
            entityName: "Specialty",
            tableName: "specialties",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                name: {columnName: "name"},
                "vetspecialties[].vetId": {relation: {entityName: "vetspecialties", refField: "vetId", refColumn: "vet_id"}},
                "vetspecialties[].specialtyId": {relation: {entityName: "vetspecialties", refField: "specialtyId", refColumn: "specialty_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {vetspecialties: {entity: VetSpecialty, fieldName: "vetspecialties", refTable: "vet_specialties", refColumns: ["specialty_id"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}}
        },
        [OWNER]: {
            entityName: "Owner",
            tableName: "owners",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                firstName: {columnName: "first_name"},
                lastName: {columnName: "last_name"},
                address: {columnName: "address"},
                city: {columnName: "city"},
                telephone: {columnName: "telephone"},
                "pets[].id": {relation: {entityName: "pets", refField: "id"}},
                "pets[].name": {relation: {entityName: "pets", refField: "name"}},
                "pets[].birthDate": {relation: {entityName: "pets", refField: "birthDate", refColumn: "birth_date"}},
                "pets[].typeId": {relation: {entityName: "pets", refField: "typeId", refColumn: "type_id"}},
                "pets[].ownerId": {relation: {entityName: "pets", refField: "ownerId", refColumn: "owner_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {pets: {entity: Pet, fieldName: "pets", refTable: "pets", refColumns: ["owner_id"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}}
        },
        [TYPE]: {
            entityName: "Type",
            tableName: "types",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                name: {columnName: "name"},
                "pets[].id": {relation: {entityName: "pets", refField: "id"}},
                "pets[].name": {relation: {entityName: "pets", refField: "name"}},
                "pets[].birthDate": {relation: {entityName: "pets", refField: "birthDate", refColumn: "birth_date"}},
                "pets[].typeId": {relation: {entityName: "pets", refField: "typeId", refColumn: "type_id"}},
                "pets[].ownerId": {relation: {entityName: "pets", refField: "ownerId", refColumn: "owner_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {pets: {entity: Pet, fieldName: "pets", refTable: "pets", refColumns: ["type_id"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}}
        },
        [VET_SPECIALTY]: {
            entityName: "VetSpecialty",
            tableName: "vet_specialties",
            fieldMetadata: {
                vetId: {columnName: "vet_id"},
                specialtyId: {columnName: "specialty_id"},
                "vet.id": {relation: {entityName: "vet", refField: "id"}},
                "vet.firstName": {relation: {entityName: "vet", refField: "firstName", refColumn: "first_name"}},
                "vet.lastName": {relation: {entityName: "vet", refField: "lastName", refColumn: "last_name"}},
                "specialty.id": {relation: {entityName: "specialty", refField: "id"}},
                "specialty.name": {relation: {entityName: "specialty", refField: "name"}}
            },
            keyFields: ["vetId", "specialtyId"],
            joinMetadata: {
                vet: {entity: Vet, fieldName: "vet", refTable: "vets", refColumns: ["id"], joinColumns: ["vet_id"], 'type: psql:ONE_TO_MANY},
                specialty: {entity: Specialty, fieldName: "specialty", refTable: "specialties", refColumns: ["id"], joinColumns: ["specialty_id"], 'type: psql:ONE_TO_MANY}
            }
        },
        [VET]: {
            entityName: "Vet",
            tableName: "vets",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                firstName: {columnName: "first_name"},
                lastName: {columnName: "last_name"},
                "vetspecialties[].vetId": {relation: {entityName: "vetspecialties", refField: "vetId", refColumn: "vet_id"}},
                "vetspecialties[].specialtyId": {relation: {entityName: "vetspecialties", refField: "specialtyId", refColumn: "specialty_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {vetspecialties: {entity: VetSpecialty, fieldName: "vetspecialties", refTable: "vet_specialties", refColumns: ["vet_id"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}}
        },
        [VISIT]: {
            entityName: "Visit",
            tableName: "visits",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                visitDate: {columnName: "visit_date"},
                description: {columnName: "description"},
                petId: {columnName: "pet_id"},
                "pet.id": {relation: {entityName: "pet", refField: "id"}},
                "pet.name": {relation: {entityName: "pet", refField: "name"}},
                "pet.birthDate": {relation: {entityName: "pet", refField: "birthDate", refColumn: "birth_date"}},
                "pet.typeId": {relation: {entityName: "pet", refField: "typeId", refColumn: "type_id"}},
                "pet.ownerId": {relation: {entityName: "pet", refField: "ownerId", refColumn: "owner_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {pet: {entity: Pet, fieldName: "pet", refTable: "pets", refColumns: ["id"], joinColumns: ["pet_id"], 'type: psql:ONE_TO_MANY}}
        },
        [PET]: {
            entityName: "Pet",
            tableName: "pets",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                name: {columnName: "name"},
                birthDate: {columnName: "birth_date"},
                typeId: {columnName: "type_id"},
                ownerId: {columnName: "owner_id"},
                "type.id": {relation: {entityName: "type", refField: "id"}},
                "type.name": {relation: {entityName: "type", refField: "name"}},
                "owner.id": {relation: {entityName: "owner", refField: "id"}},
                "owner.firstName": {relation: {entityName: "owner", refField: "firstName", refColumn: "first_name"}},
                "owner.lastName": {relation: {entityName: "owner", refField: "lastName", refColumn: "last_name"}},
                "owner.address": {relation: {entityName: "owner", refField: "address"}},
                "owner.city": {relation: {entityName: "owner", refField: "city"}},
                "owner.telephone": {relation: {entityName: "owner", refField: "telephone"}},
                "visits[].id": {relation: {entityName: "visits", refField: "id"}},
                "visits[].visitDate": {relation: {entityName: "visits", refField: "visitDate", refColumn: "visit_date"}},
                "visits[].description": {relation: {entityName: "visits", refField: "description"}},
                "visits[].petId": {relation: {entityName: "visits", refField: "petId", refColumn: "pet_id"}}
            },
            keyFields: ["id"],
            joinMetadata: {
                'type: {entity: Type, fieldName: "'type", refTable: "types", refColumns: ["id"], joinColumns: ["type_id"], 'type: psql:ONE_TO_MANY},
                owner: {entity: Owner, fieldName: "owner", refTable: "owners", refColumns: ["id"], joinColumns: ["owner_id"], 'type: psql:ONE_TO_MANY},
                visits: {entity: Visit, fieldName: "visits", refTable: "visits", refColumns: ["pet_id"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}
            }
        }
    };

    public isolated function init() returns persist:Error? {
        postgresql:Client|error dbClient = new (host = host, username = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        if defaultSchema != () {
            lock {
                foreach string key in self.metadata.keys() {
                    psql:SQLMetadata metadata = self.metadata.get(key);
                    if metadata.schemaName == () {
                        metadata.schemaName = defaultSchema;
                    }
                    map<psql:JoinMetadata>? joinMetadataMap = metadata.joinMetadata;
                    if joinMetadataMap == () {
                        continue;
                    }
                    foreach [string, psql:JoinMetadata] [_, joinMetadata] in joinMetadataMap.entries() {
                        if joinMetadata.refSchema == () {
                            joinMetadata.refSchema = defaultSchema;
                        }
                    }
                }
            }
        }
        self.persistClients = {
            [SPECIALTY]: check new (dbClient, self.metadata.get(SPECIALTY).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [OWNER]: check new (dbClient, self.metadata.get(OWNER).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [TYPE]: check new (dbClient, self.metadata.get(TYPE).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [VET_SPECIALTY]: check new (dbClient, self.metadata.get(VET_SPECIALTY).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [VET]: check new (dbClient, self.metadata.get(VET).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [VISIT]: check new (dbClient, self.metadata.get(VISIT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [PET]: check new (dbClient, self.metadata.get(PET).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS)
        };
    }

    isolated resource function get specialties(SpecialtyTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get specialties/[int id](SpecialtyTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post specialties(SpecialtyInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIALTY);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put specialties/[int id](SpecialtyUpdate value) returns Specialty|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIALTY);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/specialties/[id].get();
    }

    isolated resource function delete specialties/[int id]() returns Specialty|persist:Error {
        Specialty result = check self->/specialties/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIALTY);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get owners(OwnerTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get owners/[int id](OwnerTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post owners(OwnerInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OWNER);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put owners/[int id](OwnerUpdate value) returns Owner|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OWNER);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/owners/[id].get();
    }

    isolated resource function delete owners/[int id]() returns Owner|persist:Error {
        Owner result = check self->/owners/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OWNER);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get types(TypeTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get types/[int id](TypeTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post types(TypeInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TYPE);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put types/[int id](TypeUpdate value) returns Type|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TYPE);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/types/[id].get();
    }

    isolated resource function delete types/[int id]() returns Type|persist:Error {
        Type result = check self->/types/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TYPE);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get vetspecialties(VetSpecialtyTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get vetspecialties/[int vetId]/[int specialtyId](VetSpecialtyTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post vetspecialties(VetSpecialtyInsert[] data) returns [int, int][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET_SPECIALTY);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from VetSpecialtyInsert inserted in data
            select [inserted.vetId, inserted.specialtyId];
    }

    isolated resource function put vetspecialties/[int vetId]/[int specialtyId](VetSpecialtyUpdate value) returns VetSpecialty|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET_SPECIALTY);
        }
        _ = check sqlClient.runUpdateQuery({"vetId": vetId, "specialtyId": specialtyId}, value);
        return self->/vetspecialties/[vetId]/[specialtyId].get();
    }

    isolated resource function delete vetspecialties/[int vetId]/[int specialtyId]() returns VetSpecialty|persist:Error {
        VetSpecialty result = check self->/vetspecialties/[vetId]/[specialtyId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET_SPECIALTY);
        }
        _ = check sqlClient.runDeleteQuery({"vetId": vetId, "specialtyId": specialtyId});
        return result;
    }

    isolated resource function get vets(VetTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get vets/[int id](VetTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post vets(VetInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put vets/[int id](VetUpdate value) returns Vet|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/vets/[id].get();
    }

    isolated resource function delete vets/[int id]() returns Vet|persist:Error {
        Vet result = check self->/vets/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VET);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get visits(VisitTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get visits/[int id](VisitTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post visits(VisitInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISIT);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put visits/[int id](VisitUpdate value) returns Visit|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISIT);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/visits/[id].get();
    }

    isolated resource function delete visits/[int id]() returns Visit|persist:Error {
        Visit result = check self->/visits/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISIT);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get pets(PetTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get pets/[int id](PetTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post pets(PetInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PET);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put pets/[int id](PetUpdate value) returns Pet|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PET);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/pets/[id].get();
    }

    isolated resource function delete pets/[int id]() returns Pet|persist:Error {
        Pet result = check self->/pets/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PET);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    remote isolated function queryNativeSQL(sql:ParameterizedQuery sqlQuery, typedesc<record {}> rowType = <>) returns stream<rowType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor"
    } external;

    remote isolated function executeNativeSQL(sql:ParameterizedQuery sqlQuery) returns psql:ExecutionResult|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor"
    } external;

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

