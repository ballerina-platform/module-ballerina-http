package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.ModuleID;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Utility functions to be used in Compiler Plugin validations.
 */
public final class CompilerPluginUtils {
    public static String constructReturnTypeDescription(TypeSymbol paramType) {
        TypeDescKind typeKind = paramType.typeKind();
        if (TypeDescKind.TYPE_REFERENCE.equals(typeKind)) {
            String moduleName = paramType.getModule().flatMap(ModuleSymbol::getName).orElse("");
            String type = paramType.getName().orElse("");
            return getQualifiedType(type, moduleName);
        } else if (TypeDescKind.UNION.equals(typeKind)) {
            List<TypeSymbol> availableTypes = ((UnionTypeSymbol) paramType).memberTypeDescriptors();
            List<String> typeDescriptions = availableTypes.stream()
                    .map(CompilerPluginUtils::constructReturnTypeDescription)
                    .filter(e -> !e.isEmpty() && !e.isBlank())
                    .collect(Collectors.toList());
            return String.join("|", typeDescriptions);
        } else if (TypeDescKind.ERROR.equals(typeKind)) {
            String signature = paramType.signature();
            Optional<ModuleID> moduleIdOpt = paramType.getModule().map(ModuleSymbol::id);
            String moduleId = moduleIdOpt.map(ModuleID::toString).orElse("");
            String type = signature.replace(moduleId, "").replace(":", "");
            String moduleName = moduleIdOpt.map(ModuleID::modulePrefix).orElse("");
            return getQualifiedType(type, moduleName);
        } else {
            return "";
        }
    }

    public static String getQualifiedType(String paramType, String moduleName) {
        return moduleName.isBlank() ? paramType : String.format("%s:%s", moduleName, paramType);
    }
}
