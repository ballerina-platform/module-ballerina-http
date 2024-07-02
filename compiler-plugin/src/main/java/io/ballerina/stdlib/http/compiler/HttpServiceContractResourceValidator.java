/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.compiler.syntax.tree.AbstractNodeFactory;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.DefaultableParameterNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.IncludedRecordParameterNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.RestParameterNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.compiler.Constants.CACHE_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.COLON;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.QUERY_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_CONFIG_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;

/**
 * Validates a ballerina http resource implemented via the service contract type.
 *
 * @since 2.12.0
 */
public final class HttpServiceContractResourceValidator {

    private HttpServiceContractResourceValidator() {
    }

    public static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                        Set<String> resourcesFromServiceType, String serviceTypeName) {
        Optional<Symbol> functionDefinitionSymbol = ctx.semanticModel().symbol(member);
        if (functionDefinitionSymbol.isEmpty() ||
                !(functionDefinitionSymbol.get() instanceof ResourceMethodSymbol resourceMethodSymbol)) {
            return;
        }

        ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
        String resourceName = resourceMethodSymbol.getName().orElse("") + " " + constructResourcePathName(resourcePath);
        if (!resourcesFromServiceType.contains(resourceName)) {
            reportResourceFunctionNotAllowed(ctx, serviceTypeName, member.location());
        }

        validateAnnotationUsages(ctx, member);
    }

    public static void validateAnnotationUsages(SyntaxNodeAnalysisContext ctx,
                                                FunctionDefinitionNode resourceFunction) {
        validateAnnotationUsagesOnResourceFunction(ctx, resourceFunction);
        validateAnnotationUsagesOnInputParams(ctx, resourceFunction);
        validateAnnotationUsagesOnReturnType(ctx, resourceFunction);
    }

    public static void validateAnnotationUsagesOnResourceFunction(SyntaxNodeAnalysisContext ctx,
                                                                  FunctionDefinitionNode resourceFunction) {
        Optional<MetadataNode> metadataNodeOptional = resourceFunction.metadata();
        if (metadataNodeOptional.isEmpty()) {
            return;
        }
        NodeList<AnnotationNode> annotations = metadataNodeOptional.get().annotations();
        for (AnnotationNode annotation : annotations) {
            Node annotReference = annotation.annotReference();
            String annotName = annotReference.toString();
            if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                String[] annotStrings = annotName.split(Constants.COLON);
                if (RESOURCE_CONFIG_ANNOTATION.equals(annotStrings[annotStrings.length - 1].trim())
                        && HTTP.equals(annotStrings[0].trim())) {
                    reportResourceConfigAnnotationNotAllowed(ctx, annotation.location());
                }
            }
        }
    }

    public static void validateAnnotationUsagesOnInputParams(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode resourceFunction) {
        SeparatedNodeList<ParameterNode> parameters = resourceFunction.functionSignature().parameters();
        for (ParameterNode parameter : parameters) {
            NodeList<AnnotationNode> annotations = getAnnotationsFromParameter(parameter);
            for (AnnotationNode annotation : annotations) {
                Node annotReference = annotation.annotReference();
                String annotName = annotReference.toString();
                if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                    String[] annotationStrings = annotName.split(COLON);
                    String annotationName = annotationStrings[annotationStrings.length - 1].trim();
                    if (HTTP.equals(annotationStrings[0].trim()) &&
                            (annotationName.equals(PAYLOAD_ANNOTATION) || annotationName.equals(HEADER_ANNOTATION) ||
                            annotationName.equals(QUERY_ANNOTATION) || annotationName.equals(CALLER_ANNOTATION))) {
                        reportAnnotationNotAllowed(ctx, annotation.location(), HTTP + COLON + annotationName);
                    }
                }
            }
        }
    }

    public static NodeList<AnnotationNode> getAnnotationsFromParameter(ParameterNode parameter) {
        if (parameter instanceof RequiredParameterNode parameterNode) {
            return parameterNode.annotations();
        } else if (parameter instanceof DefaultableParameterNode parameterNode) {
            return parameterNode.annotations();
        } else if (parameter instanceof IncludedRecordParameterNode parameterNode) {
            return parameterNode.annotations();
        } else if (parameter instanceof RestParameterNode parameterNode) {
            return parameterNode.annotations();
        } else {
            return AbstractNodeFactory.createEmptyNodeList();
        }
    }

    public static void validateAnnotationUsagesOnReturnType(SyntaxNodeAnalysisContext ctx,
                                                            FunctionDefinitionNode resourceFunction) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = resourceFunction.functionSignature().
                returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }

        NodeList<AnnotationNode> annotations = returnTypeDescriptorNode.get().annotations();
        for (AnnotationNode annotation : annotations) {
            Node annotReference = annotation.annotReference();
            String annotName = annotReference.toString();
            if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                String[] annotationStrings = annotName.split(COLON);
                String annotationName = annotationStrings[annotationStrings.length - 1].trim();
                if (HTTP.equals(annotationStrings[0].trim()) &&
                        (annotationName.equals(PAYLOAD_ANNOTATION) || annotationName.equals(CACHE_ANNOTATION))) {
                    reportAnnotationNotAllowed(ctx, annotation.location(), HTTP + COLON + annotationName);
                }
            }
        }
    }

    public static String constructResourcePathName(ResourcePath resourcePath) {
        return switch (resourcePath.kind()) {
            case DOT_RESOURCE_PATH -> ".";
            case PATH_SEGMENT_LIST -> constructResourcePathNameFromSegList((PathSegmentList) resourcePath);
            default -> "^^";
        };
    }

    public static String constructResourcePathNameFromSegList(PathSegmentList pathSegmentList) {
        List<String> resourcePaths = new ArrayList<>();
        for (PathSegment pathSegment : pathSegmentList.list()) {
            switch (pathSegment.pathSegmentKind()) {
                case NAMED_SEGMENT:
                    resourcePaths.add(pathSegment.getName().orElse(""));
                    break;
                case PATH_PARAMETER:
                    resourcePaths.add("^");
                    break;
                default:
                    resourcePaths.add("^^");
            }
        }
        return resourcePaths.isEmpty() ? "" : String.join("/", resourcePaths);
    }

    private static void reportResourceFunctionNotAllowed(SyntaxNodeAnalysisContext ctx, String serviceContractType,
                                                         Location location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_158, serviceContractType);
    }

    private static void reportResourceConfigAnnotationNotAllowed(SyntaxNodeAnalysisContext ctx, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_159);
    }

    private static void reportAnnotationNotAllowed(SyntaxNodeAnalysisContext ctx, Location location,
                                                   String annotationName) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_160, annotationName);
    }
}
