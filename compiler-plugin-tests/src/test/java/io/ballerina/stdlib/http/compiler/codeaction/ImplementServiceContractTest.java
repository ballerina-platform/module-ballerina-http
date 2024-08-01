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
package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

/**
 * Tests the implement service contract resources code action when a service is implemented via
 * the service contract type.
 */
public class ImplementServiceContractTest extends AbstractCodeActionTest {
    @Test(dataProvider = "testDataProvider")
    public void testCodeActions(String srcFile, int line, int offset, CodeActionInfo expected, String resultFile)
            throws IOException {
        Path filePath = RESOURCE_PATH.resolve("ballerina_sources")
                .resolve("sample_codeaction_package_4")
                .resolve(srcFile);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(getConfigDir())
                .resolve(resultFile);

        performTest(filePath, LinePosition.from(line, offset), expected, resultPath);
    }

    @DataProvider
    private Object[][] testDataProvider() {
        return new Object[][]{
                {"service.bal", 183, 12, getExpectedCodeAction(), "result1.bal"}
        };
    }

    private CodeActionInfo getExpectedCodeAction() {
        LineRange lineRange = LineRange.from("service.bal", LinePosition.from(183, 0),
                LinePosition.from(185, 1));
        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Implement service contract resources",
                List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_105/ballerina/http/IMPLEMENT_SERVICE_CONTRACT");
        return codeAction;
    }

    protected String getConfigDir() {
        return "implement_service_contract_resources";
    }
}
