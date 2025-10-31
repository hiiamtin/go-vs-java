package com.poc.quarkus.dto;

import jakarta.validation.constraints.NotBlank;

public class CPURequest {

    @NotBlank(message = "name is required")
    private String name;

    public CPURequest() {
    }

    public CPURequest(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
