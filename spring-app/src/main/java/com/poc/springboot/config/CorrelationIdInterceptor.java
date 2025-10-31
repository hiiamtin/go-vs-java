package com.poc.springboot.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class CorrelationIdInterceptor implements HandlerInterceptor {

    private static final String CORRELATION_ID_HEADER = "X-Correlation-ID";
    private static final String CORRELATION_ID_ATTRIBUTE = "correlationId";

    @Override
    public boolean preHandle(
        HttpServletRequest request,
        HttpServletResponse response,
        Object handler
    ) throws Exception {
        // Handle correlation ID - check if exists in header, otherwise generate new one
        String correlationId = request.getHeader(CORRELATION_ID_HEADER);
        if (correlationId == null || correlationId.trim().isEmpty()) {
            correlationId = UUID.randomUUID().toString();
        }

        // Store in request attribute for potential use in controllers
        request.setAttribute(CORRELATION_ID_ATTRIBUTE, correlationId);

        // Add to response header
        response.setHeader(CORRELATION_ID_HEADER, correlationId);

        return true;
    }
}
