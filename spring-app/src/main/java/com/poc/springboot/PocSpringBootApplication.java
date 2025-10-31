package com.poc.springboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@SpringBootApplication
@EnableTransactionManagement
public class PocSpringBootApplication {

    public static void main(String[] args) {
        SpringApplication.run(PocSpringBootApplication.class, args);
    }
}
