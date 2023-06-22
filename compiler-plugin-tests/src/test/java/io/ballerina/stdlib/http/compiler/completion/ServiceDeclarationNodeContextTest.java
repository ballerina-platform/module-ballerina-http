/*
 * Copyright (c) 2023, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.completion;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Path;

/**
 * Tests the completions in ServiceDeclarationNode context.
 */
public class ServiceDeclarationNodeContextTest extends AbstractCompletionTest {

    
    @Override
    @Test(dataProvider = "completion-data-provider")
    protected void test(String filePath, int line, int offset, String configFile)
            throws IOException {
        Path filePathFromSourceRoot = RESOURCE_PATH.resolve("ballerina_sources")
                .resolve(filePath);
        Path configPath = RESOURCE_PATH.resolve("completion")
                .resolve(getConfigDir())
                .resolve(configFile);
        super.test(filePathFromSourceRoot.toString(), line, offset, configPath.toString());
    }

    @DataProvider(name = "completion-data-provider")
    @Override
    public Object[][] dataProvider() {
        return new Object[][]{
                {"sample_completion_package_1/main.bal", 22, 5, "expected_completions1.json"},
                {"sample_completion_package_2/main.bal", 22, 5, "expected_completions1.json"},
                {"sample_completion_package_2/main.bal", 35, 5, "expected_completions1.json"},
                
        };
    }

    protected String getConfigDir() {
        return "service_declaration";
    }
}
