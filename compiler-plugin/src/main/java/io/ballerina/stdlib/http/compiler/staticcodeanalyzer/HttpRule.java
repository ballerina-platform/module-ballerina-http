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
    AVOID_DEFAULT_RESOURCE_ACCESSOR(createRule(1, "Avoid allowing default resource accessor", VULNERABILITY)),
    AVOID_PERMISSIVE_CORS(createRule(2, "Avoid permissive Cross-Origin Resource Sharing", VULNERABILITY)),
    AVOID_TRAVERSING_ATTACKS(createRule(3, "Server-side requests should not be vulnerable to traversing attacks",
            VULNERABILITY)),
    AVOID_UNSECURE_REDIRECTIONS(createRule(4, "HTTP request redirections should not be open to forging attacks",
            VULNERABILITY)),
    AVOID_CREDENTIALED_WILDCARD_CORS(createRule(5,
            "Avoid allowing credentials with a wildcard Cross-Origin Resource Sharing origin", VULNERABILITY)),
    AVOID_DISABLED_TLS_VALIDATION(createRule(6, "Avoid disabling TLS certificate or host name validation",
            VULNERABILITY)),
    AVOID_WEAK_TLS_PROTOCOLS(createRule(7, "Avoid using weak TLS protocol versions", VULNERABILITY)),
    AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT(createRule(8,
            "Avoid forwarding authorization headers across redirects", VULNERABILITY)),
    ENSURE_SECURE_COOKIE_CONFIGURATION(createRule(9, "Avoid creating cookies without the secure and httpOnly flags",
            VULNERABILITY)),
    AVOID_DISABLED_AUTH_PROVIDER_TLS(createRule(10,
            "Avoid disabling TLS validation on the authentication provider client", VULNERABILITY)),
    ENSURE_JWT_VERIFICATION(createRule(11, "Avoid accepting JSON Web Tokens without verification", VULNERABILITY)),
    ENSURE_AUTHORIZATION_SCOPES(createRule(12, "Avoid authenticating requests without authorizing them",
            VULNERABILITY)),
    AVOID_AUTHENTICATION_OVER_CLEARTEXT(createRule(13,
            "Avoid accepting credentials over a listener without TLS", VULNERABILITY)),
    AVOID_UNSECURE_CALLER_REDIRECTIONS(createRule(14,
            "Caller redirections should not be open to forging attacks", VULNERABILITY)),
    AVOID_UNLIMITED_REQUEST_BODY_SIZE(createRule(15, "Avoid accepting request bodies of unlimited size",
            VULNERABILITY));

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
