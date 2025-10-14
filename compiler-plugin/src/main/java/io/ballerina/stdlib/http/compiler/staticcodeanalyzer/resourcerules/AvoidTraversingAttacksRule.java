/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules;

import io.ballerina.compiler.syntax.tree.ClientResourceAccessActionNode;
import io.ballerina.compiler.syntax.tree.ComputedResourceAccessSegmentNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpAnalysisUtils.getUsedParamName;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_TRAVERSING_ATTACKS;

public class AvoidTraversingAttacksRule implements HttpResourceRule {

    @Override
    public void analyze(HttpResourceRuleContext context) {
        List<ClientResourceAccessActionNode> clientResourceActionNodes = context.functionBodyExpressions().stream()
                .filter(exprNodeInfo -> exprNodeInfo.expression() instanceof ClientResourceAccessActionNode)
                .map(exprNodeInfo -> (ClientResourceAccessActionNode) exprNodeInfo.expression())
                .toList();

        for (ClientResourceAccessActionNode clientResourceActionNode : clientResourceActionNodes) {
            analyzeClientResourceAccess(clientResourceActionNode, context);
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_TRAVERSING_ATTACKS.getId();
    }

    @Override
    public boolean isApplicable(HttpResourceRuleContext context) {
        return !context.resourceParamNames().isEmpty() && !context.functionBodyExpressions().isEmpty();
    }

    private void analyzeClientResourceAccess(ClientResourceAccessActionNode clientResourceActionNode,
                                           HttpResourceRuleContext context) {
        SeparatedNodeList<Node> resourceAccessPaths = clientResourceActionNode.resourceAccessPath();

        for (Node resourceAccessPath : resourceAccessPaths) {
            if (resourceAccessPath instanceof ComputedResourceAccessSegmentNode computedResourceAccessSegment) {
                ExpressionNode expression = computedResourceAccessSegment.expression();
                Optional<String> usedParamName = getUsedParamName(expression);
                if (usedParamName.isPresent() && context.resourceParamNames().contains(usedParamName.get())) {
                    context.reporter().reportIssue(
                        context.document(),
                        computedResourceAccessSegment.location(),
                        getRuleId()
                    );
                }
            }
        }
    }
}
