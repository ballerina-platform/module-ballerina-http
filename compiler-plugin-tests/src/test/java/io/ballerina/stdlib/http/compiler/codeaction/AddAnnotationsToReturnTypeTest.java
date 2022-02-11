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
 * Test for adding annotations to the resource return statement.
 */
public class AddAnnotationsToReturnTypeTest extends AbstractCodeActionTest {

    @Test(dataProvider = "testDataProvider")
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
                {"service.bal", 24, 63, getAddResponseCacheConfigCodeAction(LinePosition.from(24, 60),
                        LinePosition.from(24, 66)), "result1.bal"},
                {"service.bal", 24, 63, getAddResponseContentTypeCodeAction(LinePosition.from(24, 60),
                        LinePosition.from(24, 66)), "result2.bal"}
        };
    }

    private CodeActionInfo getAddResponseCacheConfigCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add response cache configuration", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_104/ballerina/http/ADD_RESPONSE_CACHE_CONFIG");
        return codeAction;
    }

    private CodeActionInfo getAddResponseContentTypeCodeAction(LinePosition startLine, LinePosition endLine) {
        LineRange lineRange = LineRange.from("service.bal", startLine, endLine);
        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, lineRange);
        CodeActionInfo codeAction = CodeActionInfo.from("Add response content-type", List.of(locationArg));
        codeAction.setProviderName("HTTP_HINT_103/ballerina/http/ADD_RESPONSE_CONTENT_TYPE");
        return codeAction;
    }

    protected String getConfigDir() {
        return "add_annotations_to_return_type";
    }
}
