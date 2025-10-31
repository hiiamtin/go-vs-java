package com.poc.quarkus.dto;

import io.quarkus.runtime.annotations.RegisterForReflection;

@RegisterForReflection
public class CPUResponse {

    private String processedName;

    public CPUResponse() {}

    public CPUResponse(String processedName) {
        this.processedName = processedName;
    }

    public String getProcessedName() {
        return processedName;
    }

    public void setProcessedName(String processedName) {
        this.processedName = processedName;
    }
}
