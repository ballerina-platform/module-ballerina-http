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
package io.ballerina.stdlib.http.compiler.codemodifier.oas.gen;

import io.ballerina.projects.ProjectKind;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;

/**
 * {@code SingleFileOpenApiDocGenerator} generates open-api related docs for HTTP service defined in single ballerina
 * file.
 */
public class SingleFileOpenApiDocGenerator extends AbstractOpenApiDocGenerator {
    @Override
    public boolean isSupported(ProjectKind projectType) {
        return ProjectKind.SINGLE_FILE_PROJECT.equals(projectType);
    }

    @Override
    protected Path retrieveProjectRoot(Path projectRoot) {
        // For single ballerina file, project root will be the absolute path for that particular ballerina file
        // hence project root should be updated to the directory which contains the ballerina file
        Path parentDirectory = retrieveParentDirectory(projectRoot);
        if (Objects.nonNull(parentDirectory) && Files.exists(parentDirectory)) {
            return parentDirectory;
        }
        return projectRoot.isAbsolute() ? projectRoot : projectRoot.toAbsolutePath();
    }

    private Path retrieveParentDirectory(Path projectRoot) {
        if (projectRoot.isAbsolute()) {
            return projectRoot.getParent();
        } else {
            return projectRoot.toAbsolutePath().getParent();
        }
    }
}
