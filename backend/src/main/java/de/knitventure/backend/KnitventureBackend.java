package de.knitventure.backend;

import de.knitventure.backend.application.BackendStatus;
import de.knitventure.backend.application.port.ReadBackendStatus;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class KnitventureBackend {

    public static void main(String[] args) {
        SpringApplication.run(KnitventureBackend.class, args);
    }

    @Bean
    ReadBackendStatus backendStatus() {
        return new BackendStatus(BuildCommitId.read());
    }
}
