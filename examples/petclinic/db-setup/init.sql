-- Pet Clinic Database Initialization Script
-- Run this script to set up the PostgreSQL database

-- Create database (run this as superuser)
-- CREATE DATABASE petclinic;

-- Connect to petclinic database and run the following:

-- Create tables
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(80) NOT NULL UNIQUE,
    password VARCHAR(80),
    enabled BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS specialties (
    id SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS vets (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS vet_specialties (
    vet_id INTEGER REFERENCES vets(id) ON DELETE CASCADE,
    specialty_id INTEGER REFERENCES specialties(id) ON DELETE CASCADE,
    PRIMARY KEY (vet_id, specialty_id)
);

CREATE TABLE IF NOT EXISTS pet_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS owners (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(80) NOT NULL,
    telephone VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS pets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    birth_date DATE NOT NULL,
    type_id INTEGER REFERENCES pet_types(id),
    owner_id INTEGER REFERENCES owners(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS visits (
    id SERIAL PRIMARY KEY,
    visit_date DATE,
    description VARCHAR(255) NOT NULL,
    pet_id INTEGER REFERENCES pets(id) ON DELETE CASCADE
);

-- Insert sample data
INSERT INTO roles (name) VALUES 
    ('admin'), 
    ('user') 
ON CONFLICT (name) DO NOTHING;

INSERT INTO specialties (name) VALUES 
    ('radiology'), 
    ('surgery'), 
    ('dentistry'), 
    ('cardiology'),
    ('dermatology'),
    ('ophthalmology')
ON CONFLICT (name) DO NOTHING;

INSERT INTO pet_types (name) VALUES 
    ('cat'), 
    ('dog'), 
    ('bird'), 
    ('hamster'), 
    ('rabbit'),
    ('snake'),
    ('lizard')
ON CONFLICT (name) DO NOTHING;

-- Insert sample vets
INSERT INTO vets (first_name, last_name) VALUES 
    ('James', 'Carter'),
    ('Helen', 'Leary'),
    ('Linda', 'Douglas'),
    ('Rafael', 'Ortega'),
    ('Henry', 'Stevens'),
    ('Sharon', 'Jenkins')
ON CONFLICT DO NOTHING;

-- Insert sample vet specialties (assuming vet IDs 1-6 exist)
INSERT INTO vet_specialties (vet_id, specialty_id) VALUES 
    (1, 1), -- James Carter - radiology
    (2, 2), -- Helen Leary - surgery  
    (3, 3), -- Linda Douglas - dentistry
    (4, 4), -- Rafael Ortega - cardiology
    (5, 1), -- Henry Stevens - radiology
    (5, 2), -- Henry Stevens - surgery
    (6, 3)  -- Sharon Jenkins - dentistry
ON CONFLICT DO NOTHING;

-- Insert sample owners
INSERT INTO owners (first_name, last_name, address, city, telephone) VALUES 
    ('George', 'Franklin', '110 W. Liberty St.', 'Madison', '6085551023'),
    ('Betty', 'Davis', '638 Cardinal Ave.', 'Sun Prairie', '6085551749'),
    ('Eduardo', 'Rodriquez', '2693 Commerce St.', 'McFarland', '6085558763'),
    ('Harold', 'Davis', '563 Friendly St.', 'Windsor', '6085553198'),
    ('Peter', 'McTavish', '2387 S. Fair Way', 'Madison', '6085552765'),
    ('Jean', 'Coleman', '105 N. Lake St.', 'Monona', '6085552654'),
    ('Jeff', 'Black', '1450 Oak Blvd.', 'Monona', '6085555387'),
    ('Maria', 'Escobito', '345 Maple St.', 'Madison', '6085557683'),
    ('David', 'Schroeder', '2749 Blackhawk Trail', 'Madison', '6085559435'),
    ('Carlos', 'Estaban', '2335 Independence La.', 'Waunakee', '6085555487')
ON CONFLICT DO NOTHING;

-- Insert sample pets (assuming owner IDs 1-10 exist and pet type IDs 1-7 exist)
INSERT INTO pets (name, birth_date, type_id, owner_id) VALUES 
    ('Leo', '2010-09-07', 1, 1),      -- cat, George Franklin
    ('Basil', '2012-08-06', 2, 2),    -- dog, Betty Davis  
    ('Rosy', '2011-04-17', 2, 3),     -- dog, Eduardo Rodriquez
    ('Jewel', '2010-03-07', 2, 3),    -- dog, Eduardo Rodriquez
    ('Iggy', '2010-11-30', 7, 4),     -- lizard, Harold Davis
    ('George', '2010-01-20', 6, 5),   -- snake, Peter McTavish
    ('Samantha', '2012-09-04', 1, 6), -- cat, Jean Coleman
    ('Max', '2012-09-04', 1, 6),      -- cat, Jean Coleman
    ('Lucky', '2011-08-06', 3, 7),    -- bird, Jeff Black
    ('Mulligan', '2007-02-24', 2, 8), -- dog, Maria Escobito
    ('Freddy', '2010-03-09', 3, 9),   -- bird, David Schroeder
    ('Lucky', '2010-06-24', 2, 10),   -- dog, Carlos Estaban
    ('Sly', '2012-06-08', 1, 10)      -- cat, Carlos Estaban
ON CONFLICT DO NOTHING;

-- Insert sample visits (assuming pet IDs 1-13 exist)
INSERT INTO visits (visit_date, description, pet_id) VALUES 
    ('2013-01-01', 'rabies shot', 7),
    ('2013-01-02', 'rabies shot', 8),
    ('2013-01-03', 'neutered', 8),
    ('2013-01-04', 'spayed', 7),
    ('2013-01-01', 'rabies shot', 1),
    ('2013-01-02', 'rabies shot', 2),
    ('2013-01-03', 'neutered', 3),
    ('2013-01-04', 'spayed', 4),
    ('2013-01-01', 'rabies shot', 5),
    ('2013-01-02', 'rabies shot', 6),
    ('2013-01-03', 'neutered', 9),
    ('2013-01-04', 'spayed', 10),
    ('2013-01-01', 'rabies shot', 11),
    ('2013-01-02', 'rabies shot', 12),
    ('2013-01-03', 'neutered', 13)
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_visits_pet_id ON visits(pet_id);
CREATE INDEX IF NOT EXISTS idx_vet_specialties_vet_id ON vet_specialties(vet_id);
CREATE INDEX IF NOT EXISTS idx_vet_specialties_specialty_id ON vet_specialties(specialty_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_owners_last_name ON owners(last_name);

COMMIT;
