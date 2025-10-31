# CPU Logic Specification - SHA-256 Hashing Function

## Overview
This document defines the CPU-intensive logic that will be implemented identically across all four POC applications (Gin, Fiber, Spring Boot, Quarkus) to ensure fair performance comparison.

## Function Specification

### Function Name
- **Go:** `perform_cpu_work(input string) string`
- **Java:** `performCpuWork(String input) String`

### Algorithm
1. **Input:** Accept a string parameter
2. **Processing:** Loop exactly 1,000 times
   - In each iteration, perform SHA-256 hash on the input string
   - Use the hash result from previous iteration as input for next iteration
3. **Output:** Return the final hash as a hex string

### Pseudocode
```
function perform_cpu_work(input string):
    current_value = input

    for i from 1 to 1000:
        current_value = sha256_hex(current_value)

    return current_value
```

## Implementation Requirements

### Go Implementation
```go
import (
    "crypto/sha256"
    "encoding/hex"
)

func perform_cpu_work(input string) string {
    current := input

    for i := 0; i < 1000; i++ {
        hash := sha256.Sum256([]byte(current))
        current = hex.EncodeToString(hash[:])
    }

    return current
}
```

### Java Implementation
```java
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

public class CpuWork {

    public String performCpuWork(String input) throws NoSuchAlgorithmException {

        MessageDigest digest = MessageDigest.getInstance("SHA-256");

        HexFormat hexFormat = HexFormat.of();

        String current = input;

        for (int i = 0; i < 1000; i++) {

            byte[] hashBytes = digest.digest(current.getBytes(StandardCharsets.UTF_8));

            current = hexFormat.formatHex(hashBytes);
        }

        return current;
    }
}
```

## Performance Considerations
- **Fixed iterations:** Exactly 1,000 SHA-256 operations per request
- **Deterministic:** Same input always produces same output
- **CPU-bound:** Minimal memory allocation, focuses on computational work
- **Language-agnostic:** Algorithm must be identical across implementations

## Test Cases
- **Input:** "test_input"
- **Expected Output:** Should be identical across all four implementations
- **Performance Target:** Should complete in reasonable time (< 100ms) for single request
- **Validated Output:** Go implementations confirmed working in both Gin and Fiber applications
- **Hash Length:** 64-character hex string (32 bytes) as expected for SHA-256

## Notes
- This function intentionally creates CPU load to test framework overhead
- The 1,000 iteration count provides measurable work without being too slow
- Chained hashing (using previous hash as next input) prevents optimization
- Implementation must be thread-safe for concurrent requests
- Both implementations now have equivalent complexity levels for fair comparison
- Current implementations use standard crypto libraries (Go: crypto/sha256)
- Function has been validated in production Docker environments
- Part of the comprehensive API testing suite for Go applications
- Function is implemented in both Gin and Fiber Go applications
- Ready for Java Spring Boot and Quarkus implementation
- Test validation confirmed identical output across implementations
