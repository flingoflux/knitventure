package de.knitventure.backend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.JarURLConnection;
import java.util.regex.Pattern;

final class BuildCommitId {

    private static final Logger logger = LoggerFactory.getLogger(BuildCommitId.class);
    private static final String LOCAL = "local";
    private static final String MANIFEST_ATTRIBUTE = "Knitventure-Commit-Id";
    private static final Pattern COMMIT_ID = Pattern.compile("[0-9a-f]{40}");

    private BuildCommitId() {
    }

    static String read() {
        // Resolve the manifest from our own class entry, not from the first JAR on the classpath.
        var classEntry = KnitventureBackend.class.getResource("KnitventureBackend.class");
        if (classEntry == null || !"jar".equals(classEntry.getProtocol())) {
            return LOCAL;
        }

        try {
            var connection = (JarURLConnection) classEntry.openConnection();
            connection.setUseCaches(false);
            try (var jar = connection.getJarFile()) {
                var manifest = jar.getManifest();
                var value = manifest == null ? null : manifest.getMainAttributes().getValue(MANIFEST_ATTRIBUTE);
                if (value == null || value.isBlank()) {
                    logger.warn("Missing {} build metadata in the backend JAR manifest, reporting local", MANIFEST_ATTRIBUTE);
                } else if (LOCAL.equals(value) || COMMIT_ID.matcher(value).matches()) {
                    return value;
                } else {
                    logger.warn("Invalid {} build metadata in the backend JAR manifest, reporting local", MANIFEST_ATTRIBUTE);
                }
            }
        } catch (IOException e) {
            logger.warn("Cannot read {} build metadata from the backend JAR manifest, reporting local", MANIFEST_ATTRIBUTE, e);
        }
        return LOCAL;
    }
}
