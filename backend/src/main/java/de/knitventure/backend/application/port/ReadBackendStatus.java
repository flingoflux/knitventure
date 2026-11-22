package de.knitventure.backend.application.port;

import org.jmolecules.architecture.hexagonal.PrimaryPort;

@PrimaryPort
public interface ReadBackendStatus {

    String commitId();
}
