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
            "redirection to an arbitrary site.", VULNERABILITY));

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
