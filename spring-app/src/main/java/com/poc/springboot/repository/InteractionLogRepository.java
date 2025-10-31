package com.poc.springboot.repository;

import com.poc.springboot.model.InteractionLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InteractionLogRepository extends JpaRepository<InteractionLog, Integer> {
}
