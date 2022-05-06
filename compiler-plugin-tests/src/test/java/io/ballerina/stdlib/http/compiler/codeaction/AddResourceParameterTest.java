/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import org.testng.annotations.DataProvider;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

/**
 * Test for adding parameters to the resource signature.
 */
public class AddResourceParameterTest extends AbstractCodeActionTest {

//    @Test(dataProvider = "testDataProvider")
    public void testCodeActions(String srcFile, int line, int offset, CodeActionInfo expected, String resultFile)
            throws IOException {
        Path filePath = RESOURCE_PATH.resolve("ballerina_sources")
                .resolve("sample_codeaction_package_2")
                .resolve(srcFile);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(getConfigDir())
                .resolve(resultFile);

        performTest(filePath, LinePosition.from(line, offset), expected, resultPath);
    }

    @DataProvider
    private Object[][] testDataProvider() {
        return new Object[][]{
                {"service.bal", 19, 29, getAddHeaderCodeAction(LinePosition.from(19, 28),
                        LinePosition.from(19, 45)), "result1.bal"},
                {"service.bal", 23, 58, getAddHeaderCodeAction(LinePosition.from(23, 29),
                        LinePosition.from(23, 74)), "result2.bal"},
                {"service.bal", 27, 33, getAddPayloadCodeAction(LinePosition.from(27, 32),
                        LinePosition.from(27, 49)), "result3.bal"},
                {"service.bal", 31, 57, getAddPayloadCodeAction(LinePosition.from(31, 30),
                        LinePosition.from(31, 73)), "result4.bal"}
        };
    }

    private CodeActionInfo getAddPayloadCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add payload parameter", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_101/ballerina/http/ADD_PAYLOAD_PARAM");
        return codeAction;
    }

    private CodeActionInfo getAddHeaderCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add header parameter", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_102/ballerina/http/ADD_HEADER_PARAM");
        return codeAction;
    }

    protected String getConfigDir() {
        return "add_annotated_param";
    }
}
