-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "visits";
DROP TABLE IF EXISTS "pets";
DROP TABLE IF EXISTS "vet_specialties";
DROP TABLE IF EXISTS "specialties";
DROP TABLE IF EXISTS "types";
DROP TABLE IF EXISTS "vets";
DROP TABLE IF EXISTS "owners";

CREATE TABLE "owners" (
	"id"  SERIAL,
	"first_name" VARCHAR(30) NOT NULL,
	"last_name" VARCHAR(30) NOT NULL,
	"address" VARCHAR(255) NOT NULL,
	"city" VARCHAR(80) NOT NULL,
	"telephone" VARCHAR(20) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "vets" (
	"id"  SERIAL,
	"first_name" VARCHAR(30) NOT NULL,
	"last_name" VARCHAR(30) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "types" (
	"id"  SERIAL,
	"name" VARCHAR(80) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "specialties" (
	"id"  SERIAL,
	"name" VARCHAR(80) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "vet_specialties" (
	"vet_id" INT NOT NULL,
	FOREIGN KEY("vet_id") REFERENCES "vets"("id"),
	"specialty_id" INT NOT NULL,
	FOREIGN KEY("specialty_id") REFERENCES "specialties"("id"),
	PRIMARY KEY("vet_id","specialty_id")
);

CREATE TABLE "pets" (
	"id"  SERIAL,
	"name" VARCHAR(30) NOT NULL,
	"birth_date" DATE NOT NULL,
	"type_id" INT NOT NULL,
	FOREIGN KEY("type_id") REFERENCES "types"("id"),
	"owner_id" INT NOT NULL,
	FOREIGN KEY("owner_id") REFERENCES "owners"("id"),
	PRIMARY KEY("id")
);

CREATE TABLE "visits" (
	"id"  SERIAL,
	"visit_date" DATE,
	"description" VARCHAR(255) NOT NULL,
	"pet_id" INT NOT NULL,
	FOREIGN KEY("pet_id") REFERENCES "pets"("id"),
	PRIMARY KEY("id")
);


CREATE UNIQUE INDEX "specialties_name_key" ON "specialties" ("name");
CREATE INDEX "idx_owners_last_name" ON "owners" ("last_name");
CREATE UNIQUE INDEX "types_name_key" ON "types" ("name");
CREATE INDEX "idx_vet_specialties_vet_id" ON "vet_specialties" ("vet_id");
CREATE INDEX "idx_vet_specialties_specialty_id" ON "vet_specialties" ("specialty_id");
CREATE INDEX "idx_visits_pet_id" ON "visits" ("pet_id");
CREATE INDEX "idx_pets_owner_id" ON "pets" ("owner_id");
