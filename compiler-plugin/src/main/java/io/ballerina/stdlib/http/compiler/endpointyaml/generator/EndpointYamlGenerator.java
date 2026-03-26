package io.ballerina.stdlib.http.compiler.endpointyaml.generator;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;
import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeParser;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.io.IOException;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

import static io.ballerina.stdlib.http.compiler.endpointyaml.generator.FileNameGeneratorUtil.resolveContractFileName;


public class EndpointYamlGenerator {
    private final ServiceDeclarationNode node;
    private final SyntaxNodeAnalysisContext context;
    private String schemaFileName;

    private int port;
    private Endpoint endpoint;
    private Map<String, ModuleMemberVisitor> moduleVisitors = new LinkedHashMap<>();
    final PackageMemberVisitor packageMemberVisitor = new PackageMemberVisitor();
    private final FileNameGeneratorUtil fileNameGeneratorUtil;

    private static final String ARTIFACT = "artifact";
    private static final String YAML_EXTENSTION = ".yaml";
    private String schemaExtension = "";
    private String type = "";

    private record ListenerInfo(Optional<ParenthesizedArgList> argList, String type) {
    }

    private record ListenerResolution(Optional<ParenthesizedArgList> argList, String type) {
    }

    public EndpointYamlGenerator(ServiceDeclarationNode node, SyntaxNodeAnalysisContext context) {
        this.node = node;
        this.context = context;

        this.fileNameGeneratorUtil = new FileNameGeneratorUtil(context, this.schemaExtension);
        this.schemaFileName = this.fileNameGeneratorUtil.getFileName();
    }

    public Endpoint getEndpoint() {
        String moduleName = context.moduleId().moduleName();
        ensureModuleVisited(moduleName);

        ListenerInfo listenerInfo = resolveListenerInfo(moduleName);
        port = resolvePort(listenerInfo.argList());
        String basePath = buildBasePath();
        this.type = normalizeType(listenerInfo.type());

        this.schemaFileName = this.schemaFileName + schemaExtension;
        endpoint = new Endpoint(String.valueOf(port), basePath, type, this.schemaFileName);
        return this.endpoint;
    }

    private void ensureModuleVisited(String moduleName) {
        if (!packageMemberVisitor.isModuleVisited(moduleName)) {
            moduleVisitors = packageMemberVisitor.createModuleVisitor(moduleName, context.semanticModel());
            ModuleMemberVisitor moduleMemberVisitor = moduleVisitors.get(moduleName);
            packageMemberVisitor.setModuleVisitors(moduleVisitors);

            context.currentPackage()
                    .module(context.moduleId())
                    .documentIds()
                    .forEach(docId -> {
                        SyntaxTree tree = context.currentPackage()
                                .module(context.moduleId())
                                .document(docId)
                                .syntaxTree();
                        tree.rootNode().accept(moduleMemberVisitor);
                    });

            packageMemberVisitor.markModuleVisited(moduleName);
        }
    }

    private ListenerInfo resolveListenerInfo(String moduleName) {
        Optional<ParenthesizedArgList> argList = Optional.empty();
        SemanticModel semanticModel = context.semanticModel();

        for (ExpressionNode raw : node.expressions()) {
            ExpressionNode expr = unwrapCheckExpression(raw);

            if (expr.kind().equals(SyntaxKind.EXPLICIT_NEW_EXPRESSION)) {
                ExplicitNewExpressionNode explicit = (ExplicitNewExpressionNode) expr;
                argList = Optional.ofNullable(explicit.parenthesizedArgList());
                this.type = extractTypeFromExplicitNew();
                continue;
            }

            if (expr.kind().equals(SyntaxKind.IMPLICIT_NEW_EXPRESSION)) {
                ImplicitNewExpressionNode implicit = (ImplicitNewExpressionNode) expr;
                argList = implicit.parenthesizedArgList();
                this.type = extractTypeFromSymbol(semanticModel, expr);
                continue;
            }

            if (isNameReference(expr)) {
                ListenerResolution resolution = resolveNamedListener(expr, moduleName, semanticModel);
                argList = resolution.argList();
                this.type = resolution.type();
            }
        }

        return new ListenerInfo(argList, this.type);
    }

    private ExpressionNode unwrapCheckExpression(ExpressionNode expr) {
        if (expr.kind().equals(SyntaxKind.CHECK_EXPRESSION)) {
            return ((CheckExpressionNode) expr).expression();
        }
        return expr;
    }

    private String extractTypeFromExplicitNew() {
        List<String> parts = List.of(node.expressions().get(0).toString().split(" "));
        return parts.get(1).split(":")[0];
    }

    private String extractTypeFromSymbol(SemanticModel semanticModel, ExpressionNode expr) {
        Symbol symbol = semanticModel.symbol(expr).orElse(null);
        if (symbol instanceof TypeSymbol typeSymbol) {
            return typeSymbol.getModule().map(m -> m.id().moduleName()).orElse("");
        }
        return "";
    }

    private boolean isNameReference(ExpressionNode expr) {
        return expr.kind().equals(SyntaxKind.SIMPLE_NAME_REFERENCE) ||
                expr.kind().equals(SyntaxKind.QUALIFIED_NAME_REFERENCE);
    }

    private ListenerResolution resolveNamedListener(ExpressionNode expr, String moduleName,
                                                    SemanticModel semanticModel) {
        String listenerModuleName = getModuleName(semanticModel, expr);
        if (listenerModuleName.isEmpty()) {
            listenerModuleName = moduleName;
        }

        String listenerName;

        if (expr instanceof QualifiedNameReferenceNode refNode) {
            listenerName = unescapeIdentifier(refNode.identifier().text().trim());
            this.type = refNode.modulePrefix().text();
        } else {
            listenerName = unescapeIdentifier(expr.toString().trim());
        }

        Optional<ListenerDeclarationNode> declOpt =
                packageMemberVisitor.getListenerDeclaration(listenerModuleName, listenerName);

        if (declOpt.isEmpty()) {
            return new ListenerResolution(Optional.empty(), this.type);
        }

        ListenerDeclarationNode decl = declOpt.get();
        this.type = decl.typeDescriptor().get().children().get(0).toString();
        Optional<ParenthesizedArgList> argList = extractArgListFromListenerDecl(decl);
        return new ListenerResolution(argList, this.type);
    }

    private Optional<ParenthesizedArgList> extractArgListFromListenerDecl(ListenerDeclarationNode decl) {
        Node initNode = decl.initializer();
        if (initNode == null) {
            return Optional.empty();
        }
        ExpressionNode initializer = (ExpressionNode) initNode;
        initializer = unwrapCheckExpression(initializer);

        return switch (initializer.kind()) {
            case EXPLICIT_NEW_EXPRESSION ->
                    Optional.ofNullable(((ExplicitNewExpressionNode) initializer).parenthesizedArgList());
            case IMPLICIT_NEW_EXPRESSION -> ((ImplicitNewExpressionNode) initializer).parenthesizedArgList();
            default -> Optional.empty();
        };
    }

    private int resolvePort(Optional<ParenthesizedArgList> argListOpt) {
        if (argListOpt.isEmpty()) {
            return 0;
        }
        SeparatedNodeList<FunctionArgumentNode> arguments = argListOpt.get().arguments();
        int index = resolvePortFromPositionalArgs(arguments);
        resolvePortFromNamedArgs(arguments, index);
        return port;
    }

    private int resolvePortFromPositionalArgs(SeparatedNodeList<FunctionArgumentNode> arguments) {
        int index = 0;
        for (; index < arguments.size(); index++) {
            FunctionArgumentNode arg = arguments.get(index);
            if (arg instanceof NamedArgumentNode) {
                break;
            }
            if (index == 0) {
                PositionalArgumentNode portArg = (PositionalArgumentNode) arg;
                String portVal = getPortValue(portArg.expression(), context.semanticModel(), context).orElse(null);
                if (portVal != null) {
                    port = Integer.parseInt(portVal);
                }
            }
        }
        return index;
    }

    private void resolvePortFromNamedArgs(SeparatedNodeList<FunctionArgumentNode> arguments, int startIndex) {
        for (int i = startIndex; i < arguments.size(); i++) {
            FunctionArgumentNode arg = arguments.get(i);
            if (arg instanceof NamedArgumentNode namedArg) {
                if (namedArg.argumentName().toString().trim().equals("port")) {
                    String portValue = getPortValue(namedArg.expression(), context.semanticModel(), context)
                            .orElse(null);
                    if (portValue != null) {
                        port = Integer.parseInt(portValue);
                    }
                }
            }
        }
    }

    private String buildBasePath() {
        StringBuilder basePath = new StringBuilder();
        for (Node identifierNode : node.absoluteResourcePath()) {
            basePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return basePath.toString();
    }

    private String normalizeType(String rawType) {
        return switch (rawType) {
            case "http", "https" -> "REST";
            case "graphql" -> "GraphQL";
            case "grpc" -> "GRPC";
            default -> rawType;
        };
    }

    public void writeEndpointYaml() {
        Endpoint ep = getEndpoint();
        Path outPath = resolveOutputPath();
        String fileName = buildEndpointFileName(outPath);
        Path path = outPath.resolve(ARTIFACT + "/" + fileName + YAML_EXTENSTION);
        writeYaml(path, new EndpointWrapper(ep));
    }

    private Path resolveOutputPath() {
        Package currentPackage = this.context.currentPackage();
        Project project = currentPackage.project();
        Path outPath = project.targetDir();

        try {
            Files.createDirectories(Paths.get(outPath + "/" + ARTIFACT));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        return outPath;
    }

    private String buildEndpointFileName(Path outPath) {
        String base;
        if (this.type.equals("REST")){
            base = schemaFileName.split("\\.")[0].replace("_openapi", "_endpoint");
        } else {
            base = schemaFileName.split("\\.")[0]+ "_endpoint";
        }
        return resolveContractFileName(outPath.resolve(ARTIFACT), base, false);
    }

    private void writeYaml(Path path, EndpointWrapper wrapper) {
        YAMLFactory yamlFactory = YAMLFactory.builder()
                .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
                .build();
        ObjectMapper mapper = new ObjectMapper(yamlFactory);
        mapper.findAndRegisterModules();

        try (Writer writer = Files.newBufferedWriter(path)) {
            mapper.writeValue(writer, wrapper);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private Optional<String> getPortValue(ExpressionNode expression, SemanticModel semanticModel,
                                          SyntaxNodeAnalysisContext context) {
        return getPortValue(expression, false, semanticModel, context);
    }

    private Optional<String> getPortValue(ExpressionNode expression, boolean parentIsConfigurable,
                                          SemanticModel semanticModel, SyntaxNodeAnalysisContext context) {
        if (expression.kind().equals(SyntaxKind.NUMERIC_LITERAL)) {
            return resolveNumericLiteral(expression);
        }
        if (!isNameReference(expression)) {
            return Optional.empty();
        }
        return resolvePortFromVariable(expression, semanticModel, context);
    }

    private Optional<String> resolveNumericLiteral(ExpressionNode expression) {
        BasicLiteralNode literal = (BasicLiteralNode) expression;
        return Optional.of(literal.literalToken().text());
    }

    private Optional<String> resolvePortFromVariable(ExpressionNode expression,
                                                     SemanticModel semanticModel,
                                                     SyntaxNodeAnalysisContext context) {
        String moduleName = getModuleName(semanticModel, expression);
        String portVariableName = extractVariableName(expression);

        Optional<ModuleMemberVisitor.VariableDeclaredValue> varOpt =
                packageMemberVisitor.getVariableDeclaredValue(moduleName, portVariableName);

        if (varOpt.isEmpty()) {
            return Optional.empty();
        }

        ModuleMemberVisitor.VariableDeclaredValue var = varOpt.get();
        String portValueSource = String.valueOf(var.value());
        ExpressionNode portExpr = portValueSource.isEmpty() ? null : NodeParser.parseExpression(portValueSource);

        if (portExpr == null || portExpr.isMissing()) {
            return Optional.empty();
        }

        return resolvePortExpression(portExpr, var.isConfigurable(), semanticModel, context);
    }

    private String extractVariableName(ExpressionNode expression) {
        if (expression instanceof QualifiedNameReferenceNode refNode) {
            return unescapeIdentifier(refNode.identifier().text().trim());
        }
        return unescapeIdentifier(expression.toString().trim());
    }

    private Optional<String> resolvePortExpression(ExpressionNode portExpr, boolean isConfigurable,
                                                   SemanticModel semanticModel,
                                                   SyntaxNodeAnalysisContext context) {
        if (portExpr.kind().equals(SyntaxKind.REQUIRED_EXPRESSION)) {
            reportMissingPortConfigDiagnostic(context);
            return Optional.empty();
        }
        if (portExpr.kind().equals(SyntaxKind.NUMERIC_LITERAL)) {
            return resolveNumericLiteral(portExpr);
        }
        return getPortValue(portExpr, isConfigurable, semanticModel, context);
    }

    private void reportMissingPortConfigDiagnostic(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_CONFIGURATION_BEING_NULL",
                "The configurable value provided for the port should have a " +
                        "default value to generate the server details",
                DiagnosticSeverity.ERROR
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }


    public void setSchemaExtension(String schemaExtension) {
        this.schemaExtension = schemaExtension;
    }

    public static String unescapeIdentifier(String parameterName) {
        String unescapedParamName = IdentifierUtils.unescapeBallerina(parameterName);
        return unescapedParamName.replaceAll("\\\\", "").replaceAll("'", "");
    }

    public static String getModuleName(SemanticModel semanticModel, Node node) {
        Optional<Symbol> symbol = semanticModel.symbol(node);
        if (symbol.isEmpty()) {
            return "";
        }
        return getModuleName(symbol.get());
    }

    public static String getModuleName(Symbol symbol) {
        Optional<ModuleSymbol> module = symbol.getModule();
        if (module.isEmpty()) {
            return "";
        }
        return module.get().id().moduleName();
    }

}