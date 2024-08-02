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
package io.ballerina.stdlib.http.compiler.oas;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.openapi.service.mapper.ServiceToOpenAPIMapper;
import io.ballerina.openapi.service.mapper.model.OASGenerationMetaInfo;
import io.ballerina.openapi.service.mapper.model.OASResult;
import io.ballerina.openapi.service.mapper.model.ServiceDeclaration;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.swagger.v3.core.util.Json;
import io.swagger.v3.oas.models.OpenAPI;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Optional;

import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.normalizeTitle;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.diagnosticContainsErrors;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getServiceDeclarationNode;

/**
 * This class generates the OpenAPI definition resource for the service declaration node.
 *
 * @since 2.12.0
 */
public class ServiceOasGenerator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (diagnosticContainsErrors(context)) {
            return;
        }

        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(context);
        if (serviceDeclarationNode == null) {
            return;
        }

        Optional<AnnotationNode> serviceInfoAnnotation = getServiceInfoAnnotation(serviceDeclarationNode);
        if (serviceInfoAnnotation.isEmpty()) {
            return;
        }

        boolean embedOpenAPI = retrieveValueFromAnnotation(serviceInfoAnnotation.get(), "embed")
                .map(Boolean::parseBoolean)
                .orElse(false);
        if (!embedOpenAPI) {
            return;
        }

        Optional<String> contractPath = retrieveValueFromAnnotation(serviceInfoAnnotation.get(), "contract");
        if (contractPath.isPresent()) {
            return;
        }

        Optional<Symbol> symbol = context.semanticModel().symbol(serviceDeclarationNode);
        if (symbol.isEmpty()) {
            // Add warning diagnostic
            return;
        }
        String fileName = getFileName(symbol.get().hashCode());


        ServiceNode serviceNode = new ServiceDeclaration(serviceDeclarationNode, context.semanticModel());
        Optional<String> openApi = generateOpenApi(fileName, context.currentPackage().project(),
                context.semanticModel(), serviceNode);
        if (openApi.isEmpty()) {
            return;
        }

        writeOpenApiAsTargetResource(context.currentPackage().project(), fileName, openApi.get());
    }

    protected static String getFileName(int hashCode) {
        String hashString = Integer.toString(hashCode);
        return String.format("openapi_%s.json",
                hashString.startsWith("-") ? "0" + hashString.substring(1) : hashString);
    }

    protected static void writeOpenApiAsTargetResource(Project project, String fileName, String openApi) {
        Path resourcesPath = project.generatedResourcesDir();
        writeFile(fileName, openApi, resourcesPath);
    }

    protected static void writeFile(String fileName, String content, Path dirPath) {
        Path openApiPath = dirPath.resolve(fileName);
        try (FileWriter writer = new FileWriter(openApiPath.toString(), StandardCharsets.UTF_8)) {
            writer.write(content);
        } catch (IOException e) {
            // Add warning diagnostic
        }
    }

    private Optional<AnnotationNode> getServiceInfoAnnotation(ServiceDeclarationNode serviceDeclarationNode) {
        Optional<MetadataNode> metadata = serviceDeclarationNode.metadata();
        if (metadata.isEmpty()) {
            return Optional.empty();
        }
        MetadataNode metaData = metadata.get();
        NodeList<AnnotationNode> annotations = metaData.annotations();
        String serviceInfoAnnotation = String.format("%s:%s", "openapi", "ServiceInfo");
        return annotations.stream()
                .filter(ann -> serviceInfoAnnotation.equals(ann.annotReference().toString().trim()))
                .findFirst();
    }

    private Optional<String> retrieveValueFromAnnotation(AnnotationNode annotation, String fieldName) {
        return annotation
                .annotValue()
                .map(MappingConstructorExpressionNode::fields)
                .flatMap(fields ->
                        fields.stream()
                                .filter(fld -> fld instanceof SpecificFieldNode)
                                .map(fld -> (SpecificFieldNode) fld)
                                .filter(fld -> fieldName.equals(fld.fieldName().toString().trim()))
                                .findFirst()
                ).flatMap(SpecificFieldNode::valueExpr)
                .map(en -> en.toString().trim());
    }

    protected Optional<String> generateOpenApi(String fileName, Project project, SemanticModel semanticModel,
                                               ServiceNode serviceNode) {
        OASGenerationMetaInfo.OASGenerationMetaInfoBuilder builder = new
                OASGenerationMetaInfo.OASGenerationMetaInfoBuilder();
        builder.setServiceNode(serviceNode)
                .setSemanticModel(semanticModel)
                .setOpenApiFileName(fileName)
                .setBallerinaFilePath(null)
                .setProject(project);
        OASResult oasResult = ServiceToOpenAPIMapper.generateOAS(builder.build());
        Optional<OpenAPI> openApiOpt = oasResult.getOpenAPI();
        if (oasResult.getDiagnostics().stream().anyMatch(
                diagnostic -> diagnostic.getDiagnosticSeverity().equals(DiagnosticSeverity.ERROR))
                || openApiOpt.isEmpty()) {
            // Add warning diagnostic
            return Optional.empty();
        }
        OpenAPI openApi = openApiOpt.get();
        if (openApi.getInfo().getTitle() == null || openApi.getInfo().getTitle().equals("/")) {
            openApi.getInfo().setTitle(normalizeTitle(fileName));
        }
        return Optional.of(Json.pretty(openApi));
    }
}
