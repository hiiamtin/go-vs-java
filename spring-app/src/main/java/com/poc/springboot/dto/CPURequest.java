package com.poc.springboot.dto;

public class CPURequest {
    private String name;

    public CPURequest() {}

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
