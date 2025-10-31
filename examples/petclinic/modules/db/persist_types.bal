// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type Specialty record {|
    readonly int id;
    string name;

|};

public type SpecialtyOptionalized record {|
    int id?;
    string name?;
|};

public type SpecialtyWithRelations record {|
    *SpecialtyOptionalized;
    VetSpecialtyOptionalized[] vetspecialties?;
|};

public type SpecialtyTargetType typedesc<SpecialtyWithRelations>;

public type SpecialtyInsert record {|
    string name;
|};

public type SpecialtyUpdate record {|
    string name?;
|};

public type Owner record {|
    readonly int id;
    string firstName;
    string lastName;
    string address;
    string city;
    string telephone;

|};

public type OwnerOptionalized record {|
    int id?;
    string firstName?;
    string lastName?;
    string address?;
    string city?;
    string telephone?;
|};

public type OwnerWithRelations record {|
    *OwnerOptionalized;
    PetOptionalized[] pets?;
|};

public type OwnerTargetType typedesc<OwnerWithRelations>;

public type OwnerInsert record {|
    string firstName;
    string lastName;
    string address;
    string city;
    string telephone;
|};

public type OwnerUpdate record {|
    string firstName?;
    string lastName?;
    string address?;
    string city?;
    string telephone?;
|};

public type Type record {|
    readonly int id;
    string name;

|};

public type TypeOptionalized record {|
    int id?;
    string name?;
|};

public type TypeWithRelations record {|
    *TypeOptionalized;
    PetOptionalized[] pets?;
|};

public type TypeTargetType typedesc<TypeWithRelations>;

public type TypeInsert record {|
    string name;
|};

public type TypeUpdate record {|
    string name?;
|};

public type VetSpecialty record {|
    int vetId;
    int specialtyId;
|};

public type VetSpecialtyOptionalized record {|
    int vetId?;
    int specialtyId?;
|};

public type VetSpecialtyWithRelations record {|
    *VetSpecialtyOptionalized;
    VetOptionalized vet?;
    SpecialtyOptionalized specialty?;
|};

public type VetSpecialtyTargetType typedesc<VetSpecialtyWithRelations>;

public type VetSpecialtyInsert VetSpecialty;

public type VetSpecialtyUpdate record {|
    int vetId?;
    int specialtyId?;
|};

public type Vet record {|
    readonly int id;
    string firstName;
    string lastName;

|};

public type VetOptionalized record {|
    int id?;
    string firstName?;
    string lastName?;
|};

public type VetWithRelations record {|
    *VetOptionalized;
    VetSpecialtyOptionalized[] vetspecialties?;
|};

public type VetTargetType typedesc<VetWithRelations>;

public type VetInsert record {|
    string firstName;
    string lastName;
|};

public type VetUpdate record {|
    string firstName?;
    string lastName?;
|};

public type Visit record {|
    readonly int id;
    time:Date? visitDate;
    string description;
    int petId;
|};

public type VisitOptionalized record {|
    int id?;
    time:Date? visitDate?;
    string description?;
    int petId?;
|};

public type VisitWithRelations record {|
    *VisitOptionalized;
    PetOptionalized pet?;
|};

public type VisitTargetType typedesc<VisitWithRelations>;

public type VisitInsert record {|
    time:Date? visitDate;
    string description;
    int petId;
|};

public type VisitUpdate record {|
    time:Date? visitDate?;
    string description?;
    int petId?;
|};

public type Pet record {|
    readonly int id;
    string name;
    time:Date birthDate;
    int typeId;
    int ownerId;

|};

public type PetOptionalized record {|
    int id?;
    string name?;
    time:Date birthDate?;
    int typeId?;
    int ownerId?;
|};

public type PetWithRelations record {|
    *PetOptionalized;
    TypeOptionalized 'type?;
    OwnerOptionalized owner?;
    VisitOptionalized[] visits?;
|};

public type PetTargetType typedesc<PetWithRelations>;

public type PetInsert record {|
    string name;
    time:Date birthDate;
    int typeId;
    int ownerId;
|};

public type PetUpdate record {|
    string name?;
    time:Date birthDate?;
    int typeId?;
    int ownerId?;
|};

