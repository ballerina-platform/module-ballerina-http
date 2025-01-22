## Overview

This module provides a default HTTP listener implementation. The default HTTP listener is a built-in listener that
can be used to attach multiple services. Additionally, the default listener configuration can be customized.

### Usage

Following is an example of using the default HTTP listener to start an HTTP server.

```ballerina
import ballerina/http.default;

service /api on default:httpListener {

    resource function get greeting() returns string {
        return "Hello, World!";
    }
}
```

The default listener port is defaulted to 9090. The port can be changed in the `Config.toml` file.

```toml
[ballerina.http.default]
listenerPort = 8080
```

Additionally, you can configure all the listener configurations. Example configuration for changing
the HTTP version to 1.1 and enable SSL.

```toml
[ballerina.http.default.listenerConfig]
httpVersion = "1.1"

[ballerina.http.default.listenerConfig.secureSocket.key]
path = "resources/certs/key.pem"
password = "password"
```
