package com.poc.springboot.controller;

import com.poc.springboot.dto.CPURequest;
import com.poc.springboot.dto.CPUResponse;
import com.poc.springboot.dto.InteractionRequest;
import com.poc.springboot.dto.StatusResponse;
import com.poc.springboot.model.InteractionLog;
import com.poc.springboot.model.User;
import com.poc.springboot.repository.InteractionLogRepository;
import com.poc.springboot.repository.UserRepository;
import com.poc.springboot.service.InteractionService;
import com.poc.springboot.util.CpuWork;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping
public class PocController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private InteractionLogRepository interactionLogRepository;

    @Autowired
    private InteractionService interactionService;

    /**
     * API 1: GET /plaintext - Returns "Hello, World!"
     * Content-Type: text/plain
     */
    @GetMapping("/plaintext")
    public ResponseEntity<String> plaintext() {
        return ResponseEntity.ok()
                .header("Content-Type", "text/plain")
                .body("Hello, World!");
    }

    /**
     * API 2: POST /json - Receives LargeJSON, returns status
     * Tests JSON parsing/serialization performance
     */
    @PostMapping("/json")
    public ResponseEntity<StatusResponse> json(@RequestBody Map<String, Object> jsonBody) {
        // Simply return status ok - the JSON binding/parsing is the test
        return ResponseEntity.ok(new StatusResponse("ok"));
    }

    /**
     * API 3: POST /cpu - CPU intensive work
     * Performs 1000 SHA-256 hash iterations
     */
    @PostMapping("/cpu")
    public ResponseEntity<?> cpu(@RequestBody CPURequest request) {
        try {
            String result = CpuWork.performCpuWork(request.getName());
            return ResponseEntity.ok(new CPUResponse(result));
        } catch (NoSuchAlgorithmException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "SHA-256 algorithm not available");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * API 4: GET /db - Database read test
     * Queries for user with ID = 10
     */
    @GetMapping("/db")
    public ResponseEntity<?> getUser() {
        Optional<User> userOpt = userRepository.findById(10);
        if (userOpt.isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
        return ResponseEntity.ok(userOpt.get());
    }

    /**
     * API 5: POST /interaction - Realistic transaction (main test)
     * Performs complete transaction: Read user, Create interaction, Update user
     */
    @PostMapping("/interaction")
    public ResponseEntity<?> interaction(@RequestBody InteractionRequest request) {
        try {
            InteractionLog result = interactionService.processInteraction(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (IllegalArgumentException e) {
            // Handle validation errors
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());

            if (e.getMessage().contains("not found")) {
                error.put("code", "CUSTOMER_NOT_FOUND");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
            } else if (e.getMessage().contains("Invalid interaction type")) {
                error.put("code", "INVALID_INTERACTION_TYPE");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
            }
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        } catch (Exception e) {
            // Handle other errors
            Map<String, String> error = new HashMap<>();
            error.put("error", "Transaction failed");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "healthy");
        return ResponseEntity.ok(response);
    }
}
