package com.poc.springboot.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

public class CpuWork {

    private CpuWork() {
        // utility class
    }

    public static String performCpuWork(String input)
        throws NoSuchAlgorithmException {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");

        HexFormat hexFormat = HexFormat.of();

        String current = input;

        for (int i = 0; i < 1000; i++) {
            byte[] hashBytes = digest.digest(
                current.getBytes(StandardCharsets.UTF_8)
            );

            current = hexFormat.formatHex(hashBytes);
        }

        return current;
    }
}
