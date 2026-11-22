package de.knitventure.backend.application;

import de.knitventure.backend.application.port.ReadBackendStatus;
import org.jmolecules.architecture.hexagonal.Application;

@Application
public record BackendStatus(String commitId) implements ReadBackendStatus {
}
