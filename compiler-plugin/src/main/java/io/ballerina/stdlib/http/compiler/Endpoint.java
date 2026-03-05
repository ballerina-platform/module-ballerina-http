package io.ballerina.stdlib.http.compiler;

public class Endpoint {
    private final String port;
    private final String basePath;
    private final String type;
    private final String schemaPath;

    Endpoint(String port, String basePath, String type, String schemaPath) {
        this.port = port;
        this.basePath = basePath;
        this.type = type;
        this.schemaPath = schemaPath;
    }

    public String getBasePath() {
        return basePath;
    }

    public String getType() {
        return type;
    }

    public String getPort() {
        return port;
    }

    public String getSchemaPath() {
        return schemaPath;
    }
}
