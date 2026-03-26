/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
 *
 * This software is the property of WSO2 LLC. and its suppliers, if any.
 * Dissemination of any information or reproduction of any material contained
 * herein is strictly forbidden, unless permitted by WSO2 in accordance with
 * the WSO2 Commercial License available at http://wso2.com/licenses.
 * For specific language governing the permissions and limitations under
 * this license, please see the license as well as any agreement you've
 * entered into with WSO2 governing the purchase of this software and any
 * associated services.
 */
package io.ballerina.stdlib.http.compiler.endpointyaml.generator;


import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

public class PackageMemberVisitor extends NodeVisitor {

    private Map<String, ModuleMemberVisitor> moduleVisitors = new LinkedHashMap<>();

    public boolean isModuleVisited(String moduleName) {
        return false;
    };

    public void markModuleVisited(String moduleName){};

    public void setModuleVisitors(Map<String, ModuleMemberVisitor> moduleVisitors) {
        this.moduleVisitors = new LinkedHashMap<>(moduleVisitors);
    }

    public Map<String, ModuleMemberVisitor> createModuleVisitor(String moduleName, SemanticModel semanticModel) {
        ModuleMemberVisitor visitor = new ModuleMemberVisitor(semanticModel);
        moduleVisitors.put(moduleName, visitor);
        return new LinkedHashMap<>(moduleVisitors);
    }

    public Optional<ModuleMemberVisitor> getModuleVisitor(String moduleName) {
        if (moduleVisitors.containsKey(moduleName)) {
            return Optional.of(moduleVisitors.get(moduleName));
        }
        return Optional.empty();
    }

    public Optional<ListenerDeclarationNode> getListenerDeclaration(String moduleName, String listenerName) {
        return getModuleVisitor(moduleName)
                .flatMap(moduleVisitor -> moduleVisitor.getListenerDeclaration(listenerName));
    }

    public Optional<ModuleMemberVisitor.VariableDeclaredValue> getVariableDeclaredValue(String moduleName,
                                                                                        String variableName) {
        return getModuleVisitor(moduleName)
                .flatMap(moduleVisitor -> moduleVisitor.getVariableDeclaredValue(variableName));
    }
}
