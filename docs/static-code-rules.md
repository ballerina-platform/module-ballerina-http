# Static Code Rules: Ballerina HTTP Library

This document describes the static code rules that the HTTP library provides to the Ballerina static code analysis tool. The conditions that trigger each rule are specified in the [specification](spec/spec.md#18-static-code-rules).

| Id               | Kind          | Description                                                                                                                                     |
|------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| ballerina/http:1 | VULNERABILITY | [Avoid allowing default resource accessor](#1-avoid-allowing-default-resource-accessor)                                                       |
| ballerina/http:2 | VULNERABILITY | [Avoid permissive Cross-Origin Resource Sharing](#2-avoid-permissive-cross-origin-resource-sharing)                                           |
| ballerina/http:3 | VULNERABILITY | [Server-side requests should not be vulnerable to traversing attacks](#3-server-side-requests-should-not-be-vulnerable-to-traversing-attacks) |
| ballerina/http:4 | VULNERABILITY | [HTTP request redirections should not be open to forging attacks](#4-http-request-redirections-should-not-be-open-to-forging-attacks)         |

## 1. Avoid allowing default resource accessor

Using a default resource accessor allows resources to handle any HTTP method, creating CSRF vulnerabilities.

### 1.1. Why this is an issue?

Using a default resource accessor allows the resource to handle any HTTP method, including both safe and unsafe operations. HTTP methods are categorized as either **safe** or **unsafe** based on their intended purpose:

- **Safe HTTP methods** (GET, HEAD, OPTIONS) are designed for read-only operations that should not modify server state
- **Unsafe HTTP methods** (POST, PUT, DELETE) are intended for operations that change application state

### 1.2. What is the potential impact?

This creates significant security vulnerabilities, particularly with Cross-Site Request Forgery (CSRF) attacks, since CSRF protections typically only guard unsafe HTTP methods. Attackers can exploit this by performing state-changing operations through methods that should be read-only.

### 1.3. How can I fix this?

Explicitly define the authorized HTTP methods for each resource and ensure safe HTTP methods are only used for read-only operations.

**Non-compliant code:**

```ballerina
service / on new http:Listener(9090) {
    // Default resource accessor is used
    resource function default users(string id) returns string {
        ...
    }
}
```

**Compliant code:**

```ballerina
service / on new http:Listener(9090) {
    // Use explicit HTTP method
    resource function get users(string id) returns string {
        ...
    }
}
```

### 1.4. Additional Resources

- OWASP - [Top 10 2021 Category A1 - Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- OWASP - [Top 10 2021 Category A4 - Insecure Design](https://owasp.org/Top10/A04_2021-Insecure_Design/)
- OWASP - [Top 10 2017 Category A5 - Broken Access Control](https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control/)
- CWE - [CWE-352 - Cross-Site Request Forgery (CSRF)](https://cwe.mitre.org/data/definitions/352)
- [OWASP: Cross-Site Request Forgery](https://owasp.org/www-community/attacks/csrf)

## 2. Avoid permissive Cross-Origin Resource Sharing

Permissive CORS configuration allowing any origin can expose resources to unauthorized access.

### 2.1. Why this is an issue?

Cross-Origin Resource Sharing (CORS) is a mechanism that allows restricted resources on a web page to be requested from another domain outside the domain from which the resource originated. A permissive CORS configuration that allows any origin (`*`) to access server resources can lead to security vulnerabilities.

### 2.2. What is the potential impact?

This can lead to security vulnerabilities, including:

- Cross-Site Request Forgery (CSRF) attacks, when `allowCredentials` is enabled and the service accepts state-changing requests authenticated by browser-sent credentials such as cookies. CORS is not a CSRF protection mechanism by itself.
- Unauthorized data access from malicious websites
- Exposure of sensitive information to untrusted domains

### 2.3. How can I fix this?

Avoid using wildcard (`*`) in the `allowOrigins` configuration of CORS. Instead, explicitly define specific origins that are authorized to access the resources.

**Non-compliant code:**

```ballerina
@http:ServiceConfig {
    cors: {
        // Wildcard origin is used
        allowOrigins: ["*"]
    }
}
service /api/v1 on new http:Listener(9090) {
    ...
}
```

**Compliant code:**

```ballerina
@http:ServiceConfig {
    cors: {
        // Specific origins are defined
        allowOrigins: ["https://example.com", "https://another-example.com"]
    }
}
service /api/v1 on new http:Listener(9090) {
    ...
}
```

### 2.4. Additional Resources

- OWASP - [Top 10 2021 Category A5 - Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- OWASP - [Top 10 2021 Category A7 - Identification and Authentication Failures](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [developer.mozilla.org](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) - CORS
- [developer.mozilla.org](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy) - Same origin policy
- OWASP - [Top 10 2017 Category A6 - Security Misconfiguration](https://owasp.org/www-project-top-ten/2017/A6_2017-Security_Misconfiguration)
- [OWASP HTML5 Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html#cross-origin-resource-sharing) - Cross Origin Resource Sharing
- CWE - [CWE-346 - Origin Validation Error](https://cwe.mitre.org/data/definitions/346)
- CWE - [CWE-942 - Overly Permissive Cross-domain Whitelist](https://cwe.mitre.org/data/definitions/942)

## 3. Server-side requests should not be vulnerable to traversing attacks

User input in server-side requests can enable SSRF attacks against internal systems.

### 3.1. Why this is an issue?

Server-Side Request Forgery (SSRF) is a vulnerability that allows attackers to induce the server-side application to make requests to an unintended location. When applications accept user input that influences server-side HTTP requests without proper validation or sanitization, attackers can manipulate these requests.

### 3.2. What is the potential impact?

SSRF attacks can enable attackers to:

- Access internal services behind firewalls
- Scan internal networks for vulnerabilities
- Interact with metadata services in cloud environments
- Perform denial-of-service attacks
- Leverage server privileges to access restricted resources

SSRF attacks are particularly dangerous in cloud environments where metadata services can expose sensitive information such as credentials and configuration data.

Common attack patterns include:

- Manipulating URL parameters to reach internal IPs (e.g., `127.0.0.1`, `192.168.x.x`)
- Using alternate encoding schemes to bypass filters (e.g., decimal IPs, hex encoding)
- Abusing URL redirects to reach internal resources
- Using DNS rebinding to bypass hostname-based restrictions
- Exploiting non-HTTP URL schemes like `file://`, `gopher://`, or `dict://`

### 3.3. How can I fix this?

Avoid using user input directly in server-side HTTP requests. Instead, validate and sanitize all user inputs to ensure they conform to expected formats and values before using them in any server-side operations.

This rule detects only client resource access actions, such as `userClient->/users/[id]`, where a computed path segment is a parameter of the enclosing resource, or a field or member access on one, such as `[user.id]` or `[ids[0]]`. It does not analyze remote method invocations such as `userClient->get(path)`, URLs passed to the client constructor, or values derived from parameters through other expressions such as local variables, string templates or function calls. The absence of this issue therefore does not mean that the service is free of SSRF vulnerabilities.

**Non-compliant code:**

```ballerina
service /api/v1 on new http:Listener(8080) {
    resource function get users(string id) returns http:Response|error {
        http:Client userClient = check new ("http://example.com");
        // User input is used directly in the URL
        return userClient->/users/[id];
    }
}
```

**Compliant code:**

```ballerina
service /api/v1 on new http:Listener(8080) {
    resource function get users(string id) returns http:Response|error {
        // Validate the user input
        string validatedId = check getValidatedId(id);
        http:Client userClient = check new ("http://example.com");
        return userClient->/users/[validatedId];
    }
}
```

### 3.4. Additional Resources

- OWASP - [Top 10 2021 Category A10 - Server-Side Request Forgery (SSRF)](https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29/)
- OWASP - [Top 10 2017 Category A5 - Broken Access Control](https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control)
- CWE - [CWE-20 - Improper Input Validation](https://cwe.mitre.org/data/definitions/20)
- CWE - [CWE-918 - Server-Side Request Forgery (SSRF)](https://cwe.mitre.org/data/definitions/918)
- STIG Viewer - [Application Security and Development: V-222609](https://stigviewer.com/stigs/application_security_and_development/2024-12-06/finding/V-222609) - The application must not be subject to input handling vulnerabilities.

## 4. HTTP request redirections should not be open to forging attacks

Unvalidated user input in redirect URLs can enable phishing and malware distribution attacks.

### 4.1. Why this is an issue?

Open redirects occur when an application accepts user-controlled input that specifies a URL to which the user will be redirected. When these redirects are implemented without proper validation, attackers can craft redirection URLs to malicious sites.

### 4.2. What is the potential impact?

These vulnerabilities can lead to several security threats:

- **Phishing attacks:** Users are redirected to malicious sites that impersonate legitimate services
- **Credential theft:** Redirects to sites designed to steal authentication information
- **Malware distribution:** Redirects to malicious downloads
- **Security control bypass:** Leveraging user trust in the original domain
- **Cross-site scripting (XSS):** Through `javascript:` URI schemes in some browsers

Common vulnerable patterns include:

- Directly using user-supplied URLs in Location headers
- Insufficient validation of redirect destinations
- Allowing protocol-relative URLs that can lead to unexpected destinations
- Validating only prefixes of redirect URLs, which can be bypassed
- Relying on blocklists instead of allowlists for URL validation

### 4.3. How can I fix this?

Avoid using user input directly in redirection URLs. Instead, validate and sanitize all user inputs to ensure they conform to expected formats and values before using them in redirect operations.

**Non-compliant code:**

```ballerina
service /api/v1 on new http:Listener(8080) {
    resource function get redirect(string location) returns http:TemporaryRedirect {
        return {
            headers: {
                // User input is used directly in the Location header
                "Location": location
            }
        };
    }
}
```

**Compliant code:**

```ballerina
service /api/v1 on new http:Listener(8080) {
    resource function get redirect(string location) returns http:TemporaryRedirect|error {
        // Validate the user input
        string validatedLocation = check getValidatedLocation(location);
        return {
            headers: {
                "Location": validatedLocation
            }
        };
    }
}
```

### 4.4. Additional Resources

- OWASP - [Top 10 2021 Category A1 - Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- OWASP - [Top 10 2017 Category A5 - Broken Access Control](https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control)
- CWE - [CWE-20 - Improper Input Validation](https://cwe.mitre.org/data/definitions/20)
- CWE - [CWE-601 - URL Redirection to Untrusted Site ('Open Redirect')](https://cwe.mitre.org/data/definitions/601)
