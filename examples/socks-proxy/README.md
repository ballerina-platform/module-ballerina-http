# SOCKS Proxy Client

This example shows how to configure an `http:Client` to route its requests through a SOCKS proxy server using the top-level `proxy` option.

The `http:ProxyConfig` record exposes a `protocol` field of the `http:ProxyProtocol` enum, which supports three values:

- `http:HTTP` (default) - a regular HTTP CONNECT proxy.
- `http:SOCKS4` - a SOCKS version 4 proxy.
- `http:SOCKS5` - a SOCKS version 5 proxy.

## SOCKS4 vs SOCKS5

| Capability                | SOCKS4 | SOCKS5 |
|---------------------------|--------|--------|
| Username/password auth    | No     | Yes    |
| Remote (proxy-side) DNS   | No     | Yes    |

- **Authentication:** SOCKS4 does not support password authentication. If a `password` is set on a `SOCKS4` proxy configuration it is ignored with a warning. Use `SOCKS5` when the proxy requires username/password credentials.
- **Remote DNS:** With `SOCKS5`, the target host name is sent to the proxy and resolved on the proxy side. This is useful when the client cannot (or should not) resolve the destination host locally. `SOCKS4` requires the destination to be resolved by the client before connecting.

## Configuration

The proxy host, port, and credentials are read from configurable variables. Provide them through a `Config.toml` file or environment variables, for example:

```toml
proxyHost = "localhost"
proxyPort = 1080
proxyUser = "ballerina"
proxyPassword = "ballerina"
```

## Run the example

Start a SOCKS5 proxy on the configured host and port, then run:

```bash
bal run
```

The client sends a request to `https://httpbin.org/ip` through the SOCKS5 proxy and prints the response.
