package com.poc.quarkus.service;

import com.poc.quarkus.dto.InteractionRequest;
import com.poc.quarkus.model.InteractionLog;
import com.poc.quarkus.model.User;
import com.poc.quarkus.repository.InteractionLogRepository;
import com.poc.quarkus.repository.UserRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Set;

@ApplicationScoped
public class InteractionService {

    private static final Set<String> VALID_TYPES = Set.of(
        "CALL",
        "EMAIL",
        "MEETING",
        "PURCHASE",
        "SUPPORT",
        "OTHER"
    );

    @Inject
    UserRepository userRepository;

    @Inject
    InteractionLogRepository interactionLogRepository;

    @Transactional
    public InteractionLog processInteraction(InteractionRequest request) {
        if (!VALID_TYPES.contains(request.getType())) {
            throw new IllegalArgumentException(
                "Invalid interaction type. Must be one of: CALL, EMAIL, MEETING, PURCHASE, SUPPORT, OTHER"
            );
        }

        Optional<User> userOpt = userRepository.findByIdForUpdate(
            request.getCustomerId()
        );
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException(
                "Customer with ID " + request.getCustomerId() + " not found"
            );
        }

        InteractionLog interaction = new InteractionLog();
        interaction.setCustomerId(request.getCustomerId());
        interaction.setNote(request.getNote());
        interaction.setType(request.getType());
        interactionLogRepository.persist(interaction);
        interactionLogRepository.flush();

        User user = userOpt.get();
        user.setLastContactDate(LocalDateTime.now());

        return interaction;
    }
}
