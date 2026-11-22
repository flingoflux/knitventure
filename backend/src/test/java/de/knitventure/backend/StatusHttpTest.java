package de.knitventure.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.yaml.snakeyaml.Yaml;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "knitventure.build.commit-id=1111111111111111111111111111111111111111")
class StatusHttpTest {

    @LocalServerPort
    int port;

    @Test
    void acceptsBothBuildIdentifiersInTheContract() throws Exception {
        var schema = statusSchema();
        var mapper = new ObjectMapper();

        assertMatchesStatusSchema(mapper.readTree("""
                {"commitId":"local"}
                """), schema);
        assertMatchesStatusSchema(mapper.readTree("""
                {"commitId":"0123456789abcdef0123456789abcdef01234567"}
                """), schema);
    }

    @Test
    void returnsLocalForCompiledClassesDespiteARuntimeOverride() throws Exception {
        try (var client = HttpClient.newHttpClient()) {
            var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/status")).build();
            var response = client.send(request, HttpResponse.BodyHandlers.ofString());

            assertThat(response.statusCode()).isEqualTo(200);
            assertThat(response.headers().firstValue("Content-Type")).contains("application/json");
            var body = new ObjectMapper().readTree(response.body());
            assertMatchesStatusSchema(body, statusSchema());
            assertThat(body.path("commitId").asString()).isEqualTo("local");
        }
    }

    private static Map<String, Object> statusSchema() throws Exception {
        Map<String, Object> contract;
        try (var reader = Files.newBufferedReader(Path.of("../api/openapi.yaml"))) {
            contract = new Yaml().load(reader);
        }
        var paths = section(contract, "paths");
        var operation = section(section(paths, "/api/status"), "get");
        var responses = section(operation, "responses");
        var content = section(section(responses, "200"), "content");
        return section(section(content, "application/json"), "schema");
    }

    private static void assertMatchesStatusSchema(JsonNode body, Map<String, Object> schema) {
        var commitIdSchema = section(section(schema, "properties"), "commitId");

        assertThat(schema.get("required")).isEqualTo(List.of("commitId"));
        assertThat(schema.get("additionalProperties")).isEqualTo(false);
        assertThat(commitIdSchema.get("type")).isEqualTo("string");
        assertThat(body.isObject()).isTrue();
        assertThat(body.size()).isEqualTo(1);
        assertThat(body.path("commitId").isString()).isTrue();
        assertThat(body.path("commitId").asString()).matches((String) commitIdSchema.get("pattern"));
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> section(Map<String, Object> parent, String name) {
        return (Map<String, Object>) parent.get(name);
    }
}
