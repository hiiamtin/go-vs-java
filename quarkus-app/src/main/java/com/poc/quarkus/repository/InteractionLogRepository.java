package com.poc.quarkus.repository;

import com.poc.quarkus.model.InteractionLog;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class InteractionLogRepository
    implements PanacheRepositoryBase<InteractionLog, Integer> {}
