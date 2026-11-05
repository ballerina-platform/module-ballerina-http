/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import io.ballerina.scan.Rule;

import static io.ballerina.scan.RuleKind.VULNERABILITY;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.RuleFactory.createRule;

/**
 * Represents static code rules specific to the Ballerina Http package.
 */
public enum HttpRule {
    AVOID_DEFAULT_RESOURCE_ACCESSOR(createRule(1, "A resource is declared with the `default` accessor, so it " +
            "responds to every HTTP method.", VULNERABILITY)),
    AVOID_PERMISSIVE_CORS(createRule(2, "A Cross-Origin Resource Sharing configuration accepts requests from " +
            "any origin.", VULNERABILITY)),
    AVOID_TRAVERSING_ATTACKS(createRule(3, "A server-side request is sent to a URL derived from user input.",
            VULNERABILITY)),
    AVOID_UNSECURE_REDIRECTIONS(createRule(4, "A redirect target is derived from user input, allowing " +
            "redirection to an arbitrary site.", VULNERABILITY)),
    AVOID_CREDENTIALED_WILDCARD_CORS(createRule(5, "A Cross-Origin Resource Sharing configuration allows " +
            "credentials while accepting any origin.", VULNERABILITY)),
    AVOID_DISABLED_TLS_VALIDATION(createRule(6, "A client secure socket disables certificate or host name " +
            "validation.", VULNERABILITY)),
    AVOID_WEAK_TLS_PROTOCOLS(createRule(7, "A secure socket enables a weak TLS protocol version.", VULNERABILITY)),
    AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT(createRule(8, "A client forwards authorization headers when " +
            "following redirects.", VULNERABILITY)),
    ENSURE_SECURE_COOKIE_CONFIGURATION(createRule(9, "A cookie is created without both the secure and httpOnly " +
            "flags set.", VULNERABILITY)),
    AVOID_DISABLED_AUTH_PROVIDER_TLS(createRule(10, "An authentication provider client disables TLS " +
            "certificate validation.", VULNERABILITY)),
    ENSURE_JWT_VERIFICATION(createRule(11, "A JSON Web Token validator omits signature, issuer or audience " +
            "verification.", VULNERABILITY)),
    ENSURE_AUTHORIZATION_SCOPES(createRule(12, "A listener authentication configuration authenticates callers " +
            "without requiring any authorization scopes.", VULNERABILITY)),
    AVOID_AUTHENTICATION_OVER_CLEARTEXT(createRule(13, "A service accepts credentials over a listener that has " +
            "no TLS configuration.", VULNERABILITY)),
    AVOID_UNSECURE_CALLER_REDIRECTIONS(createRule(14, "A caller redirect target is derived from user input, " +
            "allowing redirection to an arbitrary site.", VULNERABILITY)),
    AVOID_UNLIMITED_REQUEST_BODY_SIZE(createRule(15, "A listener accepts request bodies of unlimited size.",
            VULNERABILITY)),
    AVOID_CACHING_AUTHENTICATED_RESPONSES(createRule(16, "A response that requires authentication may be stored " +
            "by a shared cache.", VULNERABILITY)),
    AVOID_SERVER_VERSION_DISCLOSURE(createRule(17, "The server response header discloses a product version.",
            VULNERABILITY)),
    AVOID_STALE_AUTHENTICATED_RESPONSES(createRule(18, "A cached response that requires authentication may be " +
            "served stale without revalidation.", VULNERABILITY)),
    AVOID_SHARED_CACHE_WITH_CREDENTIALS(createRule(19, "A client response cache is shared across callers while " +
            "credentials are configured.", VULNERABILITY));

    private final Rule rule;

    HttpRule(Rule rule) {
        this.rule = rule;
    }

    public int getId() {
        return this.rule.numericId();
    }

    public String getDescription() {
        return this.rule.description();
    }

    @Override
    public String toString() {
        return "{\"id\":" + this.getId() + ", \"kind\":\"" + this.rule.kind() + "\"," +
                " \"description\" : \"" + this.rule.description() + "\"}";
    }
}
