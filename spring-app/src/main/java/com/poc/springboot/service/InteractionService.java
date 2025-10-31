package com.poc.springboot.service;

import com.poc.springboot.dto.InteractionRequest;
import com.poc.springboot.model.InteractionLog;
import com.poc.springboot.model.User;
import com.poc.springboot.repository.InteractionLogRepository;
import com.poc.springboot.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InteractionService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private InteractionLogRepository interactionLogRepository;

    // Valid interaction types matching Go implementation
    private static final Map<String, Boolean> VALID_TYPES = new HashMap<>();

    static {
        VALID_TYPES.put("CALL", true);
        VALID_TYPES.put("EMAIL", true);
        VALID_TYPES.put("MEETING", true);
        VALID_TYPES.put("PURCHASE", true);
        VALID_TYPES.put("SUPPORT", true);
        VALID_TYPES.put("OTHER", true);
    }

    /**
     * Process interaction transaction - matches Go implementation exactly
     * 1. Read user with pessimistic lock
     * 2. Create interaction log
     * 3. Update user's last contact date
     * All in a single transaction
     *
     * @param request Interaction request data
     * @return Created interaction log
     * @throws RuntimeException Various business and system errors
     */
    @Transactional
    public InteractionLog processInteraction(InteractionRequest request) {
        // Validate interaction type
        if (!VALID_TYPES.containsKey(request.getType())) {
            throw new IllegalArgumentException(
                "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER"
            );
        }

        // Step 1: Read user to verify exists (with pessimistic lock)
        Optional<User> userOpt = userRepository.findByIdWithLock(
            request.getCustomerId()
        );
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException(
                "Customer with ID " + request.getCustomerId() + " not found"
            );
        }

        // Step 2: Insert interaction log
        InteractionLog interaction = new InteractionLog();
        interaction.setCustomerId(request.getCustomerId());
        interaction.setNote(request.getNote());
        interaction.setType(request.getType());
        interaction.setCreatedAt(LocalDateTime.now());

        InteractionLog savedInteraction = interactionLogRepository.save(
            interaction
        );

        // Step 3: Update user's last contact date
        User user = userOpt.get();
        user.setLastContactDate(LocalDateTime.now());
        userRepository.save(user);

        // Return the created interaction (re-fetch to ensure complete data)
        return savedInteraction;
    }
}
