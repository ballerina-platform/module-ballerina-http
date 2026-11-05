# Honor the `Retry-After` header

This example shows how to wait for the time a server asks for, using the `Retry-After` response header, before retrying a
throttled call.

The built-in `retryConfig` of `http:Client` does not read this header. It retries on its own schedule (`interval`,
`backOffFactor` and `maxWaitInterval`), so it can retry before the server allows it, get more throttled responses, and
use up all its attempts.

## The `Retry-After` header

The header carries either a number of seconds or an HTTP-date:

```text
Retry-After: 120
Retry-After: Wed, 28 Oct 2026 18:30:00 GMT
```

It is not specific to `429 Too Many Requests`. Servers also send it with `503 Service Unavailable`, and the HTTP
specification ([RFC 9110, section 10.2.3](https://www.rfc-editor.org/rfc/rfc9110#section-10.2.3)) puts no limit on the
value, so it can be seconds, hours or days. What a client does with a long value is up to the client. Waiting for hours
inside a request tends to cause timeouts in the callers upstream that are hard to trace.

## What the example does

[`client/retry_after.bal`](client/retry_after.bal) is a small helper you can copy into your own project. It uses only the
standard library.

- `callWithRetryAfter` wraps a typed call, such as a connector operation, where `4xx` and `5xx` responses are errors.
- `callWithRetryAfterResponse` wraps a call that returns an `http:Response`.
- It treats `429` and `503` as throttled, reads `Retry-After` in both forms, waits for that time and calls again. It
  never retries earlier than the server asks.
- If the server asks for more than `maxRetryAfterWait`, it does not wait. It returns a `RateLimitedError` with
  `statusCode`, `retryAfterSeconds` and `retryAt`, so the caller can reschedule the work.
- If a throttled response has no usable `Retry-After`, it waits one second before retrying.

Both limits are configurable values, so you can change them in `Config.toml`:

```toml
maxRetryAfterWait = 30
maxAttempts = 4
```

| Configurable | Default | Meaning |
|---|---|---|
| `maxRetryAfterWait` | `30` | Longest `Retry-After` wait accepted, in seconds |
| `maxAttempts` | `4` | Calls made, including the first one |

Keep `429` and `503` out of `retryConfig.statusCodes` on the same client. The client's own retry runs first and consumes
the throttled response before the helper can read its `Retry-After`.

The wrapped function runs again for each attempt, so only wrap calls that are safe to repeat.

## Run the example

Start the service, which throttles its callers, in one terminal:

```bash
cd server
bal run
```

Run the client in another terminal:

```bash
cd client
bal run
```

The client runs six scenarios:

1. The built-in `retryConfig`, which ignores the header and gives up after about three seconds.
2. A `429` with `Retry-After` in seconds.
3. A `429` with `Retry-After` as an HTTP-date.
4. A `503` with `Retry-After`.
5. A call that returns an `http:Response`.
6. A `Retry-After` of one day, which fails fast with a `RateLimitedError`.

The output is similar to:

```text
=== 1. Built-in retryConfig (interval 1s, 3 retries, statusCodes [429]); the server says Retry-After: 4 ===
[client +3.4s] final result: HTTP 429, all retries used up although the server asked for 4s between calls

=== 2. 429 with Retry-After in seconds (two failures) ===
[client +9.5s] final result: [{"id":1,"item":"laptop"},{"id":2,"item":"monitor"}]
...
=== 6. Retry-After: 86400 (one day) -> fail fast and hand back the retry time ===
time=... level=WARN module=retry_after/client message="Not retrying, the server asks for a longer wait than allowed" statusCode=429 waitSeconds=86400.0 maxWaitSeconds=30
[client +16.7s] the caller can reschedule: HTTP 429: retry allowed after 86400.0s; retryAt=2026-11-06T04:36:16.055278Z
```
