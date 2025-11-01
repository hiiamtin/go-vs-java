package com.poc.quarkus.resource;

import com.poc.quarkus.dto.CPURequest;
import com.poc.quarkus.dto.CPUResponse;
import com.poc.quarkus.dto.InteractionRequest;
import com.poc.quarkus.dto.StatusResponse;
import com.poc.quarkus.model.InteractionLog;
import com.poc.quarkus.model.User;
import com.poc.quarkus.repository.UserRepository;
import com.poc.quarkus.service.InteractionService;
import com.poc.quarkus.util.CpuWork;
import io.smallrye.common.annotation.Blocking;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Path("/")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class PocResource {

    @Inject
    UserRepository userRepository;

    @Inject
    InteractionService interactionService;

    @GET
    @Path("/plaintext")
    @Produces(MediaType.TEXT_PLAIN)
    public Response plaintext() {
        return Response.ok("Hello, World!").build();
    }

    @POST
    @Path("/json")
    public Response json(Map<String, Object> ignoredBody) {
        return Response.ok(new StatusResponse("ok")).build();
    }

    @POST
    @Path("/cpu")
    @Blocking
    public Response cpu(@Valid CPURequest request) {
        String result = CpuWork.perform(request.getName());
        return Response.ok(new CPUResponse(result)).build();
    }

    @GET
    @Path("/db")
    public Response db() {
        Optional<User> userOpt = userRepository.findByIdOptional(10);
        if (userOpt.isEmpty()) {
            return Response.status(Response.Status.NOT_FOUND)
                .entity(Map.of("error", "User not found"))
                .build();
        }
        return Response.ok(userOpt.get()).build();
    }

    @POST
    @Path("/interaction")
    public Response interaction(@Valid InteractionRequest request) {
        try {
            InteractionLog interaction = interactionService.processInteraction(
                request
            );
            return Response.status(Response.Status.CREATED)
                .entity(interaction)
                .build();
        } catch (IllegalArgumentException ex) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", ex.getMessage());
            if (ex.getMessage().contains("not found")) {
                error.put("code", "CUSTOMER_NOT_FOUND");
                return Response.status(Response.Status.NOT_FOUND)
                    .entity(error)
                    .build();
            } else if (ex.getMessage().contains("Invalid interaction type")) {
                error.put("code", "INVALID_INTERACTION_TYPE");
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity(error)
                    .build();
            }
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(error)
                .build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("error", "Transaction failed"))
                .build();
        }
    }

    @GET
    @Path("/health")
    public Response health() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "healthy");
        return Response.ok(status).build();
    }
}
