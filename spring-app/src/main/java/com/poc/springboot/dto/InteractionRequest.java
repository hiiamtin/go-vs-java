package com.poc.springboot.dto;

public class InteractionRequest {
    private Integer customerId;
    private String note;
    private String type;

    public InteractionRequest() {}

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
