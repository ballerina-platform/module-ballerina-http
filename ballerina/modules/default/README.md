## Overview

This module provides a built-in HTTP listener that serves as the default listener for attaching HTTP servers. It supports the attachment of multiple services, making it ideal for centralized deployment. Additionally, it allows for the customization of its port and configuration, offering versatility for various use cases.

## Usage Example

The following example demonstrates how to use the default HTTP listener to create an HTTP server:

```ballerina
import ballerina/http.default;

service /api on default:httpListener {

    resource function get greeting() returns string {
        return "Hello, World!";
    }
}
```

## Customizing the Listener Port

By default, the listener uses port 9090. To change this, specify the desired port in the `Config.toml` file as shown below:

```toml
[ballerina.http.default]
listenerPort = 8080
```

## Configuring the Listener

You can customize all [HTTP listener configuration](https://central.ballerina.io/ballerina/http/latest#ListenerConfiguration) in the `Config.toml` file. For detailed instructions on configuring variables, refer to the [Configurability](https://ballerina.io/learn/provide-values-to-configurable-variables/) guide.

The following example configures the HTTP listener to use HTTP/1.1 and enables SSL:

```toml
[ballerina.http.default.listenerConfig]
httpVersion = "1.1"

[ballerina.http.default.listenerConfig.secureSocket.key]
path = "resources/certs/key.pem"
password = "password"
```
