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

package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import org.testng.annotations.DataProvider;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * Test for changing header parameter type to string or string[].
 */
public class ChangeHeaderParamTypeTest extends AbstractCodeActionTest {

//    @Test(dataProvider = "testDataProvider")
    public void testCodeActions(String srcFile, int line, int offset, CodeActionInfo expected, String resultFile)
            throws IOException {
        Path filePath = RESOURCE_PATH.resolve("ballerina_sources")
                .resolve("sample_codeaction_package_1")
                .resolve(srcFile);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(getConfigDir())
                .resolve(resultFile);

        performTest(filePath, LinePosition.from(line, offset), expected, resultPath);
    }

    @DataProvider
    private Object[][] testDataProvider() {
        return new Object[][]{
                {"service.bal", 20, 49, getChangeHeaderParamToStringCodeAction(), "result1.bal"},
                {"service.bal", 20, 49, getChangeHeaderParamToStringArrayCodeAction(), "result2.bal"}
        };
    }

    private CodeActionInfo getChangeHeaderParamToStringCodeAction() {
        LineRange lineRange = LineRange.from("service.bal", LinePosition.from(20, 29),
                LinePosition.from(20, 53));
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Change header param to 'string'", List.of(locationArg));
        codeAction.setProviderName("HTTP_109/ballerina/http/CHANGE_HEADER_PARAM_STRING");
        return codeAction;
    }

    private CodeActionInfo getChangeHeaderParamToStringArrayCodeAction() {
        LineRange lineRange = LineRange.from("service.bal", LinePosition.from(20, 29),
                LinePosition.from(20, 53));
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Change header param to 'string[]'", List.of(locationArg));
        codeAction.setProviderName("HTTP_109/ballerina/http/CHANGE_HEADER_PARAM_STRING_ARRAY");
        return codeAction;
    }

    protected String getConfigDir() {
        return "change_header_param_type";
    }
}
