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
