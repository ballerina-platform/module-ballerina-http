# Pet Clinic REST API - Ballerina Implementation

A complete REST API implementation of the Spring Pet Clinic application using Ballerina programming language with PostgreSQL as the backend database.

## Features

- **Complete REST API** implementation based on OpenAPI 3.1.0 specification
- **PostgreSQL database** integration with connection pooling
- **CRUD operations** for all entities: Owners, Pets, Visits, Vets, Specialties, Pet Types
- **Comprehensive error handling** with proper HTTP status codes
- **Database initialization** with sample data
- **CORS support** for cross-origin requests
- **Structured logging** for monitoring and debugging

## API Endpoints

### Owners
- `GET /api/owners` - List all owners (with optional lastName filter)
- `POST /api/owners` - Create a new owner
- `GET /api/owners/{ownerId}` - Get owner by ID
- `PUT /api/owners/{ownerId}` - Update owner
- `DELETE /api/owners/{ownerId}` - Delete owner
- `POST /api/owners/{ownerId}/pets` - Add pet to owner
- `POST /api/owners/{ownerId}/pets/{petId}/visits` - Add visit for pet

### Pets
- `GET /api/pets` - List all pets
- `GET /api/pets/{petId}` - Get pet by ID
- `PUT /api/pets/{petId}` - Update pet
- `DELETE /api/pets/{petId}` - Delete pet

### Visits
- `GET /api/visits/{visitId}` - Get visit by ID
- `PUT /api/visits/{visitId}` - Update visit
- `DELETE /api/visits/{visitId}` - Delete visit

### Vets
- `GET /api/vets` - List all vets
- `POST /api/vets` - Create a new vet
- `GET /api/vets/{vetId}` - Get vet by ID
- `PUT /api/vets/{vetId}` - Update vet
- `DELETE /api/vets/{vetId}` - Delete vet

### Specialties
- `GET /api/specialties` - List all specialties
- `POST /api/specialties` - Create a new specialty
- `GET /api/specialties/{specialtyId}` - Get specialty by ID
- `PUT /api/specialties/{specialtyId}` - Update specialty
- `DELETE /api/specialties/{specialtyId}` - Delete specialty

### Pet Types
- `GET /api/pettypes` - List all pet types
- `POST /api/pettypes` - Create a new pet type
- `GET /api/pettypes/{petTypeId}` - Get pet type by ID
- `PUT /api/pettypes/{petTypeId}` - Update pet type
- `DELETE /api/pettypes/{petTypeId}` - Delete pet type

## Prerequisites

- **Ballerina Swan Lake** (2201.8.5 or later)
- **PostgreSQL** (12 or later)
- **Java** (21 or later) - Required by Ballerina

## Installation & Setup

### 1. Install Ballerina

Refer [Install Ballerina]()

### 2. Clone this repository

```bash
git clone https://github.com/ballerina-platform/module-ballerina-http
```

### 3. Setup PostgreSQL Database

```bash
# Navigate to the db-setup directory in the examples folder
cd module-ballerina-http/examples/petclinic/db-setup

# Use docker compose to bring up the postgres service
docker compose up
```

### 4. Configure Application

Edit `Config.toml` to match your database configuration:

```toml
[databaseConfig]
database = "petclinic"
username = "petclinic"
password = "petclinic"
host = "localhost"
port = 5432

[serverConfig]
host = "localhost"
port = 9966
```

### 5. Build and Run

```bash
# Navigate to project directory
cd petclinic-ballerina

# Build the project
bal build

# Run the application
bal run
```

The API will be available at: `http://localhost:9966/petclinic/api`

## Project Structure

```
petclinic-ballerina/
├── Ballerina.toml          # Project configuration and dependencies
├── Cloud.toml              # Cloud/Docker configuration
├── Config.toml             # Application configuration 
├── README.md               # This file
├── dao.bal                 # Data access object layer
├── db-setup                
│   ├── docker-compose.yml  # docker compose file for postgres service
│   └── init.sql            # db schema and sample data for the app
├── openapi.json            # OpenAPI spec of spring petclinic
├── service.bal             # REST API service endpoints
└── types.bal               # Data types and schemas
```

## Error Handling

The API returns standardized error responses following the Problem Details RFC 7807:

```json
{
  "type": "http://localhost:9966/petclinic/api",
  "title": "Not Found",
  "status": 404,
  "detail": "Owner not found",
  "timestamp": "2024-01-01T12:00:00Z",
  "schemaValidationErrors": []
}
```

## Testing

### Using curl
```bash
# Get all owners
curl -X GET http://localhost:9966/petclinic/api/owners

# Create a new owner
curl -X POST http://localhost:9966/petclinic/api/owners \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "address": "123 Main St",
    "city": "Springfield",
    "telephone": "5551234567"
  }'

# Get owner by ID
curl -X GET http://localhost:9966/petclinic/api/owners/1
```

### Using Postman
Import the OpenAPI specification to generate a Postman collection with all endpoints.

## Logging

The application uses Ballerina's built-in logging framework. Logs include:
- Service startup and initialization
- Database operations
- Error conditions
- Request processing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the original Spring Pet Clinic project for details.

## Acknowledgments

- Based on the Spring Pet Clinic REST API
- Built with Ballerina programming language
- Uses PostgreSQL for data persistence
