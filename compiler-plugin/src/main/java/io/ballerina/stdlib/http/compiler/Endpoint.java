package io.ballerina.stdlib.http.compiler;

public class Endpoint {
    private final String port;
    private final String basePath;
    private final String type;

    Endpoint(String port, String basePath, String type) {
        this.port = port;
        this.basePath = basePath;
        this.type = type;
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
}
