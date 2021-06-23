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
