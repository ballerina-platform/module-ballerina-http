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

/**
 * Test for adding annotated parameter to the resource signature.
 */
public class AddAnnotatedParameterTest extends AbstractCodeActionTest {

    @Test(dataProvider = "testDataProvider")
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
                {"service.bal", 19, 30, getAddHeaderCodeAction(LinePosition.from(19,29),
                        LinePosition.from(19,46)), "result1.bal"},
                {"service.bal", 23, 59, getAddHeaderCodeAction(LinePosition.from(23,30),
                        LinePosition.from(23,75)), "result2.bal"},
                {"service.bal", 27, 50, getAddPayloadCodeAction(LinePosition.from(27,33),
                        LinePosition.from(27,50)), "result3.bal"},
                {"service.bal", 31, 58, getAddPayloadCodeAction(LinePosition.from(31,31),
                        LinePosition.from(31,74)), "result4.bal"}
        };
    }

    private CodeActionInfo getAddPayloadCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add payload parameter", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_101/ballerina/http/ADD_PAYLOAD_PARAM");
        return codeAction;
    }

    private CodeActionInfo getAddHeaderCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add header parameter", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_102/ballerina/http/ADD_HEADER_PARAM");
        return codeAction;
    }

    protected String getConfigDir() {
        return "add_annotated_param";
    }
}
