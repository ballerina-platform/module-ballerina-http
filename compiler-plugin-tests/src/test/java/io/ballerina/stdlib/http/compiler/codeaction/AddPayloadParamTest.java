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
 * Test for adding payload parameter to the resource signature.
 */
public class AddPayloadParamTest extends AbstractCodeActionTest {

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
                {"service.bal", 24, 65, getExpectedCodeAction(), "result1.bal"}
        };
    }

    private CodeActionInfo getExpectedCodeAction() {
        LineRange lineRange = LineRange.from("service.bal", LinePosition.from(24, 60),
                LinePosition.from(24, 66));
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Change return type to 'error?'", List.of(locationArg));
        codeAction.setProviderName("HTTP_118/ballerina/http/CHANGE_RETURN_TYPE_WITH_CALLER");
        return codeAction;
    }

    protected String getConfigDir() {
        return "add_payload_param";
    }
}
