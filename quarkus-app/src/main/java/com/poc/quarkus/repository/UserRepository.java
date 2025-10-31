package com.poc.quarkus.repository;

import com.poc.quarkus.model.User;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.LockModeType;
import java.util.Optional;

@ApplicationScoped
public class UserRepository implements PanacheRepositoryBase<User, Integer> {

    public Optional<User> findByIdForUpdate(Integer id) {
        return Optional.ofNullable(
            getEntityManager().find(
                User.class,
                id,
                LockModeType.PESSIMISTIC_WRITE
            )
        );
    }
}
