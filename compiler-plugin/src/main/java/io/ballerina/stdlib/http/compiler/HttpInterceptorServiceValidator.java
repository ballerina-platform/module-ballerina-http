/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_CONTEXT_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.RESPONSE_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getCtxTypes;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.subtypeOf;

/**
 * Validates a Ballerina Http Interceptor Service.
 */
public class HttpInterceptorServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        List<Diagnostic> diagnostics = syntaxNodeAnalysisContext.semanticModel().diagnostics();
        boolean erroneousCompilation = diagnostics.stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));
        if (erroneousCompilation) {
            return;
        }

        ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) syntaxNodeAnalysisContext.node();
        NodeList<Token>  tokens = classDefinitionNode.classTypeQualifiers();
        if (tokens.isEmpty()) {
            return;
        }
        if (!tokens.stream().allMatch(token -> token.text().equals(Constants.SERVICE_KEYWORD))) {
            return;
        }

        NodeList<Node> members = classDefinitionNode.members();
        validateInterceptorTypeAndProceed(syntaxNodeAnalysisContext, members, getCtxTypes(syntaxNodeAnalysisContext));
    }

    private static void validateInterceptorTypeAndProceed(SyntaxNodeAnalysisContext ctx, NodeList<Node> members,
                                                          Map<String, TypeSymbol> typeSymbols) {
        String interceptorType = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                String typeReference = ((TypeReferenceNode) member).typeName().toString();
                switch (typeReference) {
                    case Constants.HTTP_REQUEST_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.REQUEST_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                    case Constants.HTTP_REQUEST_ERROR_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.REQUEST_ERROR_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                    case Constants.HTTP_RESPONSE_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.RESPONSE_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                    case Constants.HTTP_RESPONSE_ERROR_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.RESPONSE_ERROR_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }

                }
            }
        }
        if (interceptorType != null) {
            validateInterceptorMethod(ctx, members, interceptorType, typeSymbols);
        }
    }

    private static void validateInterceptorMethod(SyntaxNodeAnalysisContext ctx, NodeList<Node> members,
                                                  String type, Map<String, TypeSymbol> typeSymbols) {
        FunctionDefinitionNode resourceFunctionNode = null;
        FunctionDefinitionNode remoteFunctionNode = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                if (!isResourceSupported(type)) {
                    reportResourceFunctionNotAllowed(ctx, member, type);
                }
                if (resourceFunctionNode == null) {
                    resourceFunctionNode = (FunctionDefinitionNode) member;
                } else {
                    reportMultipleResourceFunctionsFound(ctx, (FunctionDefinitionNode) member);
                }
            } else if (member instanceof FunctionDefinitionNode &&
                    isRemoteFunction(ctx, (FunctionDefinitionNode) member)) {
                if (isValidRemoteFunctionName(ctx, type, member)) {
                    if (remoteFunctionNode == null) {
                        remoteFunctionNode = (FunctionDefinitionNode) member;
                    }
                }
            }
        }
        if (isResourceSupported(type)) {
            if (resourceFunctionNode != null) {
                HttpInterceptorResourceValidator.validateResource(ctx, resourceFunctionNode, type, typeSymbols);
            } else {
                reportResourceFunctionNotFound(ctx, type);
            }
        } else {
            if (remoteFunctionNode != null) {
                validateRemoteMethod(ctx, remoteFunctionNode, type, typeSymbols);
            } else {
                reportRemoteFunctionNotFound(ctx, type);
            }
        }
    }

    private static boolean isValidRemoteFunctionName(SyntaxNodeAnalysisContext ctx, String type, Node member) {
        if (isResourceSupported(type)) {
            reportRemoteFunctionNotAllowed(ctx, member, type);
            return false;
        } else {
            String remoteFunctionName = String.valueOf(((FunctionDefinitionNode) member).functionName()).trim();
            if (isResponseErrorInterceptor(type)) {
                if (!remoteFunctionName.equals(Constants.INTERCEPT_RESPONSE_ERROR)) {
                    reportInvalidRemoteFunction(ctx, member, remoteFunctionName, type,
                            Constants.INTERCEPT_RESPONSE_ERROR);
                    return false;
                } else {
                    return true;
                }
            } else if (!remoteFunctionName.equals(Constants.INTERCEPT_RESPONSE)) {
                reportInvalidRemoteFunction(ctx, member, remoteFunctionName, type, Constants.INTERCEPT_RESPONSE);
                return false;
            } else {
                return true;
            }
        }
    }

    public static MethodSymbol getMethodSymbol(SyntaxNodeAnalysisContext context,
                                               FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = null;
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> symbol = semanticModel.symbol(functionDefinitionNode);
        if (symbol.isPresent()) {
            methodSymbol = (MethodSymbol) symbol.get();
        }
        return methodSymbol;
    }

    public static boolean isRemoteFunction(SyntaxNodeAnalysisContext context,
                                           FunctionDefinitionNode functionDefinitionNode) {
        return isRemoteFunction(getMethodSymbol(context, functionDefinitionNode));
    }

    private static boolean isResponseErrorInterceptor(String type) {
        return type.equals(Constants.RESPONSE_ERROR_INTERCEPTOR);
    }

    public static boolean isRemoteFunction(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    private static boolean isResourceSupported(String type) {
        return type.equals(Constants.REQUEST_INTERCEPTOR) || type.equals(Constants.REQUEST_ERROR_INTERCEPTOR);
    }
    private static void validateRemoteMethod(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                             String type, Map<String, TypeSymbol> typeSymbols) {
        validateInputParamType(ctx, member, type, typeSymbols);
        HttpCompilerPluginUtil.extractInterceptorReturnTypeAndValidate(ctx, typeSymbols, member,
                HttpDiagnostic.HTTP_141);
    }

    private static void validateInputParamType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                               String type, Map<String, TypeSymbol> typeSymbols) {
        boolean callerPresent = false;
        boolean requestPresent = false;
        boolean responsePresent = false;
        boolean requestCtxPresent = false;
        boolean errorPresent = false;
        Optional<Symbol> remoteMethodSymbolOptional = ctx.semanticModel().symbol(member);
        Location paramLocation = member.location();
        if (remoteMethodSymbolOptional.isEmpty()) {
            return;
        }
        Optional<List<ParameterSymbol>> parametersOptional =
                ((MethodSymbol) remoteMethodSymbolOptional.get()).typeDescriptor().params();
        if (parametersOptional.isEmpty()) {
            return;
        }
        for (ParameterSymbol param : parametersOptional.get()) {
            String paramType = param.typeDescriptor().signature();
            Optional<Location> paramLocationOptional = param.getLocation();
            if (paramLocationOptional.isPresent()) {
                paramLocation = paramLocationOptional.get();
            }
            Optional<String> nameOptional = param.getName();
            String paramName = nameOptional.orElse("");

            TypeDescKind kind = param.typeDescriptor().typeKind();
            TypeSymbol typeSymbol = param.typeDescriptor();
            if (subtypeOf(typeSymbols, typeSymbol, CALLER_OBJ_NAME)) {
                callerPresent = isObjectPresent(ctx, paramLocation, callerPresent, paramName,
                        HttpDiagnostic.HTTP_115);
            } else if (subtypeOf(typeSymbols, typeSymbol, REQUEST_OBJ_NAME)) {
                requestPresent = isObjectPresent(ctx, paramLocation, requestPresent, paramName,
                        HttpDiagnostic.HTTP_116);
            } else if (subtypeOf(typeSymbols, typeSymbol, RESPONSE_OBJ_NAME)) {
                responsePresent = isObjectPresent(ctx, paramLocation, responsePresent, paramName,
                        HttpDiagnostic.HTTP_139);
            } else if (subtypeOf(typeSymbols, typeSymbol, REQUEST_CONTEXT_OBJ_NAME)) {
                requestCtxPresent = isObjectPresent(ctx, paramLocation, requestCtxPresent, paramName,
                        HttpDiagnostic.HTTP_121);
            } else if (isResponseErrorInterceptor(type) && kind == TypeDescKind.ERROR) {
                errorPresent = isObjectPresent(ctx, paramLocation, errorPresent, paramName,
                            HttpDiagnostic.HTTP_122);
            } else {
                reportInvalidParameterType(ctx, paramLocation, paramType, isResponseErrorInterceptor(type));
            }
        }
        if (isResponseErrorInterceptor(type) && !errorPresent) {
            HttpCompilerPluginUtil.reportMissingParameterError(ctx, member.location(), Constants.REMOTE_KEYWORD);
        }
    }

    private static boolean isObjectPresent(SyntaxNodeAnalysisContext ctx, Location location,
                                           boolean objectPresent, String paramName, HttpDiagnostic code) {
        if (objectPresent) {
            HttpCompilerPluginUtil.updateDiagnostic(ctx, location, code, paramName);
        }
        return true;
    }

    private static void reportInvalidParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                   String typeName, boolean isResponseErrorInterceptor) {
        String functionName = isResponseErrorInterceptor ? Constants.INTERCEPT_RESPONSE_ERROR :
                Constants.INTERCEPT_RESPONSE;
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_140, typeName, functionName);
    }

    private static void reportMultipleReferencesFound(SyntaxNodeAnalysisContext ctx, TypeReferenceNode node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_123,
                                                node.typeName().toString());
    }

    private static void reportMultipleResourceFunctionsFound(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HttpDiagnostic.HTTP_124.getCode(),
                HttpDiagnostic.HTTP_124.getMessage(), HttpDiagnostic.HTTP_124.getSeverity());
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private static void reportResourceFunctionNotFound(SyntaxNodeAnalysisContext ctx, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, ctx.node().location(), HttpDiagnostic.HTTP_132, type);
    }

    private static void reportRemoteFunctionNotFound(SyntaxNodeAnalysisContext ctx, String type) {
        String requiredFunctionName = isResponseErrorInterceptor(type) ? Constants.INTERCEPT_RESPONSE_ERROR :
                Constants.INTERCEPT_RESPONSE;
        DiagnosticInfo diagnosticInfo = HttpCompilerPluginUtil.getDiagnosticInfo(HttpDiagnostic.HTTP_135,
                type, requiredFunctionName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, ctx.node().location()));
    }

    private static void reportResourceFunctionNotAllowed(SyntaxNodeAnalysisContext ctx, Node node, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_136, type);
    }

    private static void reportRemoteFunctionNotAllowed(SyntaxNodeAnalysisContext ctx, Node node, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_137, type);
    }

    private static void reportInvalidRemoteFunction(SyntaxNodeAnalysisContext ctx, Node node, String functionName,
                                                    String interceptorType, String requiredFunctionName) {
        DiagnosticInfo diagnosticInfo = HttpCompilerPluginUtil.getDiagnosticInfo(HttpDiagnostic.HTTP_138,
                                        functionName, interceptorType, requiredFunctionName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }
}
