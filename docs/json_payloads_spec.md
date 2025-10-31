# JSON Payload Specifications

## Overview
This document defines JSON payload structures that will be used across all four POC applications for API testing and performance benchmarking.

**Enhanced Features:**
- All payloads now support correlation ID header tracing
- Validated in both Gin and Fiber Go applications
- Ready for Spring Boot and Quarkus implementation
- Enhanced error handling and validation requirements

## Payload 1: LargeJSON
Used for API 2 (`POST /json`) to test JSON parsing/serialization performance with complex data structures.

### Structure
- Complex customer object with 50+ fields
- Includes nested objects, arrays, various data types
- Represents realistic CRM customer data
- **Validated in:** Gin and Fiber applications with correlation ID support
- **JSON Parsing Test:** Used to measure framework JSON handling performance

### JSON Schema
```json
{
  "customerId": 12345,
  "personalInfo": {
    "firstName": "John",
    "lastName": "Smith",
    "middleName": "Robert",
    "title": "Mr.",
    "dateOfBirth": "1985-06-15",
    "gender": "M",
    "ssn": "123-45-6789",
    "maritalStatus": "Married"
  },
  "contactInfo": {
    "primaryEmail": "john.smith@example.com",
    "secondaryEmail": "john.smith.work@example.com",
    "phoneNumber": "+1-555-123-4567",
    "mobileNumber": "+1-555-987-6543",
    "workPhone": "+1-555-555-1234"
  },
  "address": {
    "street": "123 Main St",
    "street2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA",
    "addressType": "Home"
  },
  "billingAddress": {
    "street": "456 Business Ave",
    "street2": "Suite 200",
    "city": "New York",
    "state": "NY",
    "zipCode": "10002",
    "country": "USA",
    "addressType": "Billing"
  },
  "preferences": {
    "language": "en",
    "timezone": "America/New_York",
    "currency": "USD",
    "marketingConsent": true,
    "emailConsent": true,
    "smsConsent": false
  },
  "membership": {
    "tier": "Premium",
    "joinDate": "2020-01-15",
    "expiryDate": "2025-01-15",
    "autoRenew": true,
    "points": 15000,
    "status": "Active"
  },
  "financial": {
    "creditScore": 750,
    "annualIncome": 120000,
    "employmentStatus": "Employed",
    "employer": "Tech Corp",
    "jobTitle": "Senior Engineer"
  },
  "interactions": [
    {
      "id": 1,
      "type": "Email",
      "date": "2024-01-10T10:30:00Z",
      "subject": "Monthly Newsletter",
      "status": "Delivered"
    },
    {
      "id": 2,
      "type": "Call",
      "date": "2024-01-08T14:20:00Z",
      "duration": 300,
      "agent": "Agent Smith",
      "status": "Completed"
    },
    {
      "id": 3,
      "type": "Purchase",
      "date": "2024-01-05T09:15:00Z",
      "amount": 299.99,
      "product": "Premium Subscription",
      "status": "Completed"
    }
  ],
  "products": [
    {
      "id": "PROD001",
      "name": "Premium Support",
      "category": "Service",
      "price": 99.99,
      "active": true
    },
    {
      "id": "PROD002",
      "name": "Cloud Storage",
      "category": "Digital",
      "price": 19.99,
      "active": true
    }
  ],
  "metadata": {
    "createdAt": "2020-01-15T00:00:00Z",
    "updatedAt": "2024-01-10T15:30:00Z",
    "lastLogin": "2024-01-10T08:45:00Z",
    "createdBy": "system",
    "updatedBy": "agent_john",
    "version": 3
  },
  "customFields": {
    "referralSource": "web",
    "campaign": "summer2023",
    "preferredContactMethod": "email",
    "vipStatus": "gold",
    "riskScore": 0.15,
    "lifetimeValue": 15000.00
  }
}
```

## Payload 2: InteractionJSON
Used for API 5 (`POST /interaction`) - the main realistic transaction test that combines database operations.

### Structure
- Simple object for customer interaction logging
- Used in the primary business transaction test case

### JSON Schema
```json
{
  "customerId": 123,
  "note": "Customer inquired about billing cycle and payment options. Discussed quarterly billing discount. Customer interested in upgrading to enterprise plan.",
  "type": "CALL"
}
```

## Implementation Notes

### Field Types
- `customerId`: Integer (foreign key to users table)
- `note`: String/Text (up to 1000 characters recommended)
- `type`: String (enum values: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER)

### Validation Requirements
- `customerId` must be a valid positive integer
- `note` should not be empty
- `type` should be one of the predefined interaction types

### Database Mapping
This payload maps directly to the `interaction_log` table via GORM:
- `customerId` → `customer_id` (GORM struct field)
- `note` → `note` (GORM struct field)
- `type` → `type` (GORM struct field with validation)
- `created_at` → auto-generated timestamp (GORM autoCreateTime)

**GORM Implementation Notes:**
- Uses GORM struct tags for proper mapping
- Automatic type conversion and validation
- Integrated with correlation ID middleware for tracing

## Testing Considerations

### Load Test Variations
For comprehensive testing, consider these variations:
1. **Small notes:** 50-100 characters
2. **Large notes:** 800-1000 characters
3. **Different types:** CALL, EMAIL, MEETING, etc.
4. **Various customerIds:** 1-100 (matching seed data)

### Performance Impact
- **LargeJSON**: Tests JSON parsing/serialization overhead
- **InteractionJSON**: Tests database transaction performance
- Both should be identical across all four implementations

**Current Implementation Status:**
✅ **Gin Application:** Both payloads validated with correlation ID tracing
✅ **Fiber Application:** Both payloads validated with correlation ID tracing
✅ **Database Operations:** GORM ORM with proper struct mapping
✅ **Error Handling:** Consistent HTTP status codes and JSON responses
✅ **Performance Testing:** Ready for load testing with k6 scripts

**Testing Enhancements:**
- Correlation ID header automatically generated/traced for all requests
- GORM provides type-safe database operations
- Enhanced error messages for debugging support
- Production-ready Docker containerization with arm64 support

### Example Test Cases

#### Valid Request
```json
{
  "customerId": 42,
  "note": "Follow-up call regarding product demo feedback. Customer expressed satisfaction with features but concerned about pricing.",
  "type": "CALL"
}
```

#### Edge Cases
- Maximum valid customerId: 100
- Empty note: Should be rejected
- Invalid type: Should be rejected
- Non-existent customerId: Should return appropriate error

## Constants

### Interaction Types (ENUM)
- `CALL` - Phone call interaction
- `EMAIL` - Email communication
- `MEETING` - In-person or virtual meeting
- `PURCHASE` - Transaction/purchase event
- `SUPPORT` - Customer support interaction
- `OTHER` - Miscellaneous interaction type

These specifications must be implemented exactly as defined across all four applications to ensure fair performance comparison.

**Ready for Java Implementation:**
- Go implementations (Gin + Fiber) provide complete reference
- Both payloads validated with GORM ORM and correlation ID middleware
- Database schema and business logic fully tested
- Performance baseline established for Java comparison

**Implementation Requirements for Java Applications:**
- Use same JSON structures and field names
- Implement identical validation rules
- Support correlation ID header functionality
- Use JPA/Hibernate equivalent to GORM mapping
- Maintain identical error response formats