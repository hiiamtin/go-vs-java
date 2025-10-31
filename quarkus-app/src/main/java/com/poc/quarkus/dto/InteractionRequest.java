package com.poc.quarkus.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class InteractionRequest {

    @NotNull(message = "customerId is required")
    @JsonProperty("customerId")
    private Integer customerId;

    @NotBlank(message = "note is required")
    private String note;

    @NotBlank(message = "type is required")
    private String type;

    public InteractionRequest() {
    }

    public InteractionRequest(Integer customerId, String note, String type) {
        this.customerId = customerId;
        this.note = note;
        this.type = type;
    }

    public Integer getCustomerId() {
        return customerId;
    }

    public void setCustomerId(Integer customerId) {
        this.customerId = customerId;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }
}
