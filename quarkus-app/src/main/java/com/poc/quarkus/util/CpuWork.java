package com.poc.quarkus.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * Utility class implementing the shared CPU workload: 1000 SHA-256 hashes.
 */
public final class CpuWork {

    private CpuWork() {
    }

    public static String perform(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            HexFormat hexFormat = HexFormat.of();
            String current = input;

            for (int i = 0; i < 1000; i++) {
                byte[] hashBytes = digest.digest(current.getBytes(StandardCharsets.UTF_8));
                current = hexFormat.formatHex(hashBytes);
            }

            return current;
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
