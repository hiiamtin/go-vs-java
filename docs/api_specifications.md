# API Specifications
## Overview
This document defines the five REST API endpoints that will be implemented identically across all four POC applications (Gin, Fiber, Spring Boot, Quarkus) for performance comparison.

## General Specifications
- **Base URL:** `http://localhost:8080`
- **Content-Type:** `application/json` (except API 1)
- **HTTP Methods:** GET, POST as specified
- **Response Format:** JSON (except API 1)
- **Error Handling:** HTTP status codes + JSON error message
- **Database:** PostgreSQL connection required for APIs 4 and 5

## API 1: Plaintext Response
**Purpose:** Test pure HTTP overhead without JSON processing

### Endpoint
```
GET /plaintext
```

### Request
No body required.

### Response
- **Content-Type:** `text/plain`
- **Body:** `Hello, World!`
- **Status:** `200 OK`

### Example
**Request:**
```http
GET /plaintext HTTP/1.1
Host: localhost:8080
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 13

Hello, World!
```

## API 2: JSON Parsing
**Purpose:** Test JSON deserialization and serialization performance

### Endpoint
```
POST /json
```

### Request
- **Content-Type:** `application/json`
- **Body:** LargeJSON object (50+ fields, see json_payloads_spec.md)

### Response
- **Content-Type:** `application/json`
- **Body:** `{"status": "ok"}`
- **Status:** `200 OK`

### Example
**Request:**
```http
POST /json HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "customerId": 12345,
  "personalInfo": {
    "firstName": "John",
    "lastName": "Smith",
    ...
  },
  ...
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 16

{"status": "ok"}
```

## API 3: CPU Work
**Purpose:** Test CPU-intensive operation performance

### Endpoint
```
POST /cpu
```

### Request
- **Content-Type:** `application/json`
- **Body:** `{"name": "string"}`

### Response
- **Content-Type:** `application/json`
- **Body:** `{"processed_name": "sha256_hash_result"}`
- **Status:** `200 OK`

### Processing Logic
1. Extract `name` from request JSON
2. Call `perform_cpu_work(name)` function (1,000 SHA-256 iterations)
3. Return the hash result

### Example
**Request:**
```http
POST /cpu HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"name": "test_input"}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"processed_name": "3a7bd3e2360a1f9b5c8b8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8"}
```

## API 4: Database Read
**Purpose:** Test simple database query performance

### Endpoint
```
GET /db
```

### Request
No query parameters required. Always queries for user with ID = 10.

### Response
- **Content-Type:** `application/json`
- **Body:** User object from database
- **Status:** `200 OK` or `404 Not Found`

### Database Query
```sql
SELECT id, name, email, last_contact_date 
FROM users 
WHERE id = 10
```

### Response Schema
```json
{
  "id": 10,
  "name": "Benjamin McDonald",
  "email": "benjamin.mcdonald@example.com",
  "last_contact_date": "2023-10-05T09:25:00Z"
}
```

### Example
**Request:**
```http
GET /db HTTP/1.1
Host: localhost:8080
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 10,
  "name": "Benjamin McDonald",
  "email": "benjamin.mcdonald@example.com",
  "last_contact_date": "2023-10-05T09:25:00Z"
}
```

## API 5: Realistic Transaction (Primary Test)
**Purpose:** Test complete business transaction with database operations

### Endpoint
```
POST /interaction
```

### Request
- **Content-Type:** `application/json`
- **Body:** InteractionJSON object

### Response
- **Content-Type:** `application/json`
- **Body:** Newly created interaction_log record
- **Status:** `201 Created` or `400/404/500` for errors

### Transaction Logic
1. **Start Database Transaction**
2. **Validate Request:**
   - Verify `customerId` exists in `users` table
   - Validate `note` is not empty
   - Validate `type` is valid interaction type
3. **Read Operation:**
   - `SELECT * FROM users WHERE id = customerId`
4. **Write Operation:**
   - `INSERT INTO interaction_log (customer_id, note, type, created_at) 
     VALUES (?, ?, ?, NOW())`
5. **Update Operation:**
   - `UPDATE users SET last_contact_date = NOW() WHERE id = customerId`
6. **Commit Transaction**
7. **Return the newly created interaction_log record**

### Response Schema
```json
{
  "id": 123,
  "customer_id": 42,
  "note": "Customer inquiry about billing options...",
  "type": "CALL",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Example
**Request:**
```http
POST /interaction HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "customerId": 42,
  "note": "Customer inquired about billing cycle and payment options. Discussed quarterly billing discount.",
  "type": "CALL"
}
```

**Response:**
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 123,
  "customer_id": 42,
  "note": "Customer inquired about billing cycle and payment options. Discussed quarterly billing discount.",
  "type": "CALL",
  "created_at": "2024-01-15T10:30:00.123456Z"
}
```

## Error Handling
### Standard Error Response Format
```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

### Common HTTP Status Codes
- `200 OK`: Successful request (APIs 1, 2, 3, 4)
- `201 Created`: Resource created (API 5)
- `400 Bad Request`: Invalid request body/validation
- `404 Not Found`: Resource not found (APIs 4, 5)
- `500 Internal Server Error`: Server/database error

### Error Examples

#### API 5 - Customer Not Found
```http
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "Customer with ID 999 not found",
  "code": "CUSTOMER_NOT_FOUND"
}
```

#### API 5 - Invalid Interaction Type
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER",
  "code": "INVALID_INTERACTION_TYPE"
}
```

### Database Configuration Requirements
### Connection Settings
- **Host:** db (Docker container name for Mac OS single-machine setup)
- **Port:** 5432
- **Database:** poc_db
- **Username:** poc_user
- **Password:** poc_password
- **Pool Size:** Minimum 10 connections
- **Network:** Must connect to Docker network `poc-net`

### Tables Required
- `users` (100 pre-populated records)
- `interaction_log` (empty initially)

## Performance Considerations
### Critical Requirements
1. **API 5** must use proper database transactions
2. All operations must be atomic - rollback on any failure
3. Connection pooling must be configured
4. Prepared statements should be used for queries
5. Transaction isolation level: READ COMMITTED

### Implementation Notes
- API 5 is the **primary performance metric** - Realistic Transaction
- Other APIs are micro-benchmarks to isolate specific bottlenecks
- All implementations must use the same database schema
- Transaction handling must be equivalent across frameworks
- Error responses should be consistent in format and timing
- **Mac OS Single-Machine Setup:** Database hostname must be `db` not `localhost` to work with Docker networking

## Testing Validation
### Success Criteria
1. All endpoints respond with correct status codes
2. Database state changes correctly after API 5 calls
3. Transaction rollback works on errors
4. Performance measurements are consistent
5. Load testing can run without errors

### Validation Tests
1. **Unit Tests:** Individual endpoint functionality
2. **Integration Tests:** Database operations
3. **Transaction Tests:** Rollback scenarios
4. **Load Tests:** Performance benchmarks
5. **Consistency Tests:** Identical behavior across frameworks

These specifications must be implemented exactly as defined across all four applications to ensure fair and accurate performance comparison.