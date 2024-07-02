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

import io.ballerina.projects.DocumentId;
import io.ballerina.projects.ModuleId;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * {@code OpenApiDocContextHandler} will manage the shared context among compiler plugin tasks.
 */
public final class OpenApiDocContextHandler {
    private static OpenApiDocContextHandler instance;

    private final List<OpenApiDocContext> contexts;

    private OpenApiDocContextHandler(List<OpenApiDocContext> contexts) {
        this.contexts = contexts;
    }

    public static OpenApiDocContextHandler getContextHandler() {
        synchronized (OpenApiDocContextHandler.class) {
            if (Objects.isNull(instance)) {
                instance = new OpenApiDocContextHandler(new ArrayList<>());
            }
        }
        return instance;
    }

    private void addContext(OpenApiDocContext context) {
        synchronized (this.contexts) {
            this.contexts.add(context);
        }
    }

    /**
     * Update the shared context for open-api doc generation.
     * @param moduleId of the current module
     * @param documentId of the current file
     * @param definition to be added to the context
     */
    public void updateContext(ModuleId moduleId, DocumentId documentId,
                              OpenApiDocContext.OpenApiDefinition definition) {
        Optional<OpenApiDocContext> contextOpt = retrieveContext(moduleId, documentId);
        if (contextOpt.isPresent()) {
            OpenApiDocContext context = contextOpt.get();
            synchronized (context) {
                context.updateOpenApiDetails(definition);
            }
            return;
        }
        OpenApiDocContext context = new OpenApiDocContext(moduleId, documentId);
        context.updateOpenApiDetails(definition);
        addContext(context);
    }

    private Optional<OpenApiDocContext> retrieveContext(ModuleId moduleId, DocumentId documentId) {
        return this.contexts.stream()
                .filter(ctx -> equals(ctx, moduleId, documentId))
                .findFirst();
    }

    public List<OpenApiDocContext> retrieveAvailableContexts() {
        return Collections.unmodifiableList(contexts);
    }

    private boolean equals(OpenApiDocContext context, ModuleId moduleId, DocumentId documentId) {
        int hashCodeForCurrentContext = Objects.hash(context.getModuleId(), context.getDocumentId());
        return hashCodeForCurrentContext == Objects.hash(moduleId, documentId);
    }
}
