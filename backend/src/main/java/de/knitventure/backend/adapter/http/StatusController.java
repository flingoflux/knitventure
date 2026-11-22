package de.knitventure.backend.adapter.http;

import de.knitventure.backend.application.port.ReadBackendStatus;
import org.jmolecules.architecture.hexagonal.PrimaryAdapter;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@PrimaryAdapter
@RestController
public class StatusController {

    private final ReadBackendStatus backendStatus;

    StatusController(ReadBackendStatus backendStatus) {
        this.backendStatus = backendStatus;
    }

    @GetMapping(path = "/api/status", produces = MediaType.APPLICATION_JSON_VALUE)
    StatusResponse status() {
        return new StatusResponse(backendStatus.commitId());
    }

    record StatusResponse(String commitId) {
    }
}
