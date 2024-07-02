/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.codemodifier.oas.context;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.tools.diagnostics.Diagnostic;

import java.util.ArrayList;
import java.util.List;

/**
 * {@code ServiceNodeAnalysisContext} will store service node analysis context.
 */
public class ServiceNodeAnalysisContext {

    private final ServiceNode node;
    private final ModuleId moduleId;
    private final DocumentId documentId;
    private final SyntaxTree syntaxTree;
    private final SemanticModel semanticModel;
    private final Package currentPackage;
    private final List<Diagnostic> diagnostics;

    public ServiceNodeAnalysisContext(Package currentPackage, ModuleId moduleId, DocumentId documentId,
                                      SyntaxTree syntaxTree, SemanticModel semanticModel,
                                      ServiceNode node) {
        this.moduleId = moduleId;
        this.documentId = documentId;
        this.syntaxTree = syntaxTree;
        this.semanticModel = semanticModel;
        this.currentPackage = currentPackage;
        this.diagnostics = new ArrayList<>();
        this.node = node;
    }

    public ServiceNode node() {
        return node;
    }

    public ModuleId moduleId() {
        return moduleId;
    }

    public DocumentId documentId() {
        return documentId;
    }

    public SyntaxTree syntaxTree() {
        return syntaxTree;
    }

    public SemanticModel semanticModel() {
        return semanticModel;
    }

    public Package currentPackage() {
        return currentPackage;
    }

    public void reportDiagnostic(Diagnostic diagnosticCode) {
        diagnostics.add(diagnosticCode);
    }

    public List<Diagnostic> diagnostics() {
        return diagnostics;
    }
}
