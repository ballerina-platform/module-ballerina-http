import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

@sql:Name {value: "specialties"}
public type Specialty record {|
    @sql:Generated
    readonly int id;
    @sql:Varchar {length: 80}
    @sql:UniqueIndex {name: "specialties_name_key"}
    string name;
    VetSpecialty[] vetspecialties;
|};

@sql:Name {value: "owners"}
public type Owner record {|
    @sql:Generated
    readonly int id;
    @sql:Name {value: "first_name"}
    @sql:Varchar {length: 30}
    string firstName;
    @sql:Name {value: "last_name"}
    @sql:Varchar {length: 30}
    @sql:Index {name: "idx_owners_last_name"}
    string lastName;
    @sql:Varchar {length: 255}
    string address;
    @sql:Varchar {length: 80}
    string city;
    @sql:Varchar {length: 20}
    string telephone;
    Pet[] pets;
|};

@sql:Name {value: "types"}
public type Type record {|
    @sql:Generated
    readonly int id;
    @sql:Varchar {length: 80}
    @sql:UniqueIndex {name: "types_name_key"}
    string name;
    Pet[] pets;
|};

@sql:Name {value: "vet_specialties"}
public type VetSpecialty record {|
    @sql:Name {value: "vet_id"}
    @sql:Index {name: "idx_vet_specialties_vet_id"}
    readonly int vetId;
    @sql:Name {value: "specialty_id"}
    @sql:Index {name: "idx_vet_specialties_specialty_id"}
    readonly int specialtyId;
    @sql:Relation {keys: ["vetId"]}
    Vet vet;
    @sql:Relation {keys: ["specialtyId"]}
    Specialty specialty;
|};

@sql:Name {value: "vets"}
public type Vet record {|
    @sql:Generated
    readonly int id;
    @sql:Name {value: "first_name"}
    @sql:Varchar {length: 30}
    string firstName;
    @sql:Name {value: "last_name"}
    @sql:Varchar {length: 30}
    string lastName;
    VetSpecialty[] vetspecialties;
|};

@sql:Name {value: "visits"}
public type Visit record {|
    @sql:Generated
    readonly int id;
    @sql:Name {value: "visit_date"}
    time:Date? visitDate;
    @sql:Varchar {length: 255}
    string description;
    @sql:Name {value: "pet_id"}
    @sql:Index {name: "idx_visits_pet_id"}
    int? petId;
    @sql:Relation {keys: ["petId"]}
    Pet pet;
|};

@sql:Name {value: "pets"}
public type Pet record {|
    @sql:Generated
    readonly int id;
    @sql:Varchar {length: 30}
    string name;
    @sql:Name {value: "birth_date"}
    time:Date birthDate;
    @sql:Name {value: "type_id"}
    int? typeId;
    @sql:Name {value: "owner_id"}
    @sql:Index {name: "idx_pets_owner_id"}
    int? ownerId;
    @sql:Relation {keys: ["typeId"]}
    Type 'type;
    @sql:Relation {keys: ["ownerId"]}
    Owner owner;
    Visit[] visits;
|};

