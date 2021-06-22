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

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * This class includes tests for Ballerina Http compiler plugin.
 */
public class CompilerPluginTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("build", "target", "ballerina-distribution")
            .toAbsolutePath();

    private static final String HTTP_101 = "HTTP_101";
    private static final String HTTP_102 = "HTTP_102";
    private static final String HTTP_103 = "HTTP_103";
    private static final String HTTP_104 = "HTTP_104";
    private static final String HTTP_105 = "HTTP_105";
    private static final String HTTP_106 = "HTTP_106";
    private static final String HTTP_107 = "HTTP_107";
    private static final String HTTP_108 = "HTTP_108";
    private static final String HTTP_109 = "HTTP_109";
    private static final String HTTP_110 = "HTTP_110";
    private static final String HTTP_111 = "HTTP_111";
    private static final String HTTP_112 = "HTTP_112";
    private static final String HTTP_113 = "HTTP_113";
    private static final String HTTP_114 = "HTTP_114";
    private static final String HTTP_115 = "HTTP_115";
    private static final String HTTP_116 = "HTTP_116";
    private static final String HTTP_117 = "HTTP_117";
    private static final String HTTP_118 = "HTTP_118";

    private static final String REMOTE_METHODS_NOT_ALLOWED = "remote methods are not allowed in http:Service";

    private Package loadPackage(String path) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private void assertError(DiagnosticResult diagnosticResult, int index, String message, String code) {
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.diagnostics().toArray()[index];
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(), message);
        Assert.assertEquals(diagnostic.diagnosticInfo().code(), code);
    }

    private void assertTrue(DiagnosticResult diagnosticResult, int index, String message, String code) {
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.diagnostics().toArray()[index];
        Assert.assertTrue(diagnostic.diagnosticInfo().messageFormat().contains(message));
        Assert.assertEquals(diagnostic.diagnosticInfo().code(), code);
    }

    @Test
    public void testInvalidMethodTypes() {
        Package currentPackage = loadPackage("sample_package_1");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 3);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assert.assertEquals(result.diagnosticInfo().messageFormat(), REMOTE_METHODS_NOT_ALLOWED);
                Assert.assertEquals(result.diagnosticInfo().code(), HTTP_101);
            }
        });
    }

    @Test
    public void testInValidReturnTypes() {
        Package currentPackage = loadPackage("sample_package_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 3);
        assertError(diagnosticResult, 0, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|error', but found 'http:Client'", HTTP_102);
        assertError(diagnosticResult, 1, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|error', but found 'error[]'", HTTP_102);
        assertError(diagnosticResult, 2, "invalid resource method return type: expected 'anydata|http:Response" +
                "|http:StatusCodeRecord|error', but found 'map<http:Client>'", HTTP_102);
    }

    @Test
    public void testInValidAnnotations() {
        Package currentPackage = loadPackage("sample_package_3");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 2);
        assertError(diagnosticResult, 1, "invalid resource method annotation type: expected 'http:ResourceConfig', " +
                "but found 'test:Config '", HTTP_103);
    }

    @Test
    public void testInValidInputPayloadArgs() {
        Package currentPackage = loadPackage("sample_package_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 4);
        assertError(diagnosticResult, 0, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
        assertError(diagnosticResult, 1, "invalid payload parameter type: 'json[]'", HTTP_107);
        assertError(diagnosticResult, 2, "invalid annotation type on param 'a': expected one of the following types: " +
                "'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_104);
        assertError(diagnosticResult, 3,
                    "invalid resource parameter type: 'table<http_test/sample_4:0.1.0:Person> key(id)'", HTTP_106);
    }

    @Test
    public void testInValidInputHeaderArgs() {
        Package currentPackage = loadPackage("sample_package_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 6);
        assertError(diagnosticResult, 0, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 1, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
        assertError(diagnosticResult, 2, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 3,
                    "invalid union type of header param 'abc': a string or an array of a string can only be union " +
                            "with '()'. Eg: string|() or string[]|()",
                    HTTP_110);
        assertError(diagnosticResult, 4, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 5,
                    "invalid union type of header param 'abc': a string or an array of a string can only be union " +
                            "with '()'. Eg: string|() or string[]|()",
                    HTTP_110);
    }

    @Test
    public void testInValidCallerInfoArgs() {
        Package currentPackage = loadPackage("sample_package_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 3);
        assertError(diagnosticResult, 0, "invalid type of caller param 'abc': expected 'http:Caller'", HTTP_111);
        assertError(diagnosticResult, 1, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
        assertError(diagnosticResult, 2, "invalid type of caller param 'abc': expected 'http:Caller'", HTTP_111);
    }

    @Test
    public void testInValidNonAnnotatedArgs() {
        Package currentPackage = loadPackage("sample_package_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 4);
        assertTrue(diagnosticResult, 0, "invalid resource parameter type: 'ballerina/http", HTTP_106);
        assertTrue(diagnosticResult, 1, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertTrue(diagnosticResult, 2, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertTrue(diagnosticResult, 3, "invalid resource parameter type: 'http_test/sample_6", HTTP_106);
    }

    @Test
    public void testInValidQueryInfoArgs() {
        Package currentPackage = loadPackage("sample_package_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 6);
        assertError(diagnosticResult, 0, "invalid resource parameter type: 'json'", HTTP_106);
        assertTrue(diagnosticResult, 1, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertError(diagnosticResult, 2, "invalid union type of query param 'a': 'string', 'int', 'float', " +
                "'boolean', 'decimal' type or the array types of them can only be union with '()'. Eg: string? or " +
                "int[]?", HTTP_113);
        assertError(diagnosticResult, 3, "invalid union type of query param 'a': 'string', 'int', 'float', " +
                "'boolean', 'decimal' type or the array types of them can only be union with '()'. Eg: string? or " +
                "int[]?", HTTP_113);
        assertError(diagnosticResult, 4, "invalid union type of query param 'a': 'string', 'int', 'float', " +
                "'boolean', 'decimal' type or the array types of them can only be union with '()'. Eg: string? or " +
                "int[]?", HTTP_113);
        assertError(diagnosticResult, 5, "invalid type of query param 'a': expected one of the 'string', " +
                "'int', 'float', 'boolean', 'decimal' types or the array types of them", HTTP_112);
    }

    @Test
    public void testListenerTypes() {
        Package currentPackage = loadPackage("sample_package_9");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 6);
        diagnosticResult.diagnostics().stream().filter(err -> err.diagnosticInfo().code().contains(HTTP_106)).map(
                err -> err.diagnosticInfo().messageFormat().contains(
                        "invalid resource parameter type: 'ballerina/http")).forEach(Assert::assertTrue);
    }

    @Test
    public void testCallerInfoAnnotation() {
        Package currentPackage = loadPackage("sample_package_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 7);
        assertError(diagnosticResult, 0, "incompatible respond method argument type : expected " +
                "'int' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 1, "incompatible respond method argument type : expected " +
                "'decimal' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 2, "incompatible respond method argument type : expected " +
                "'Person' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 3, "incompatible respond method argument type : expected " +
                "'string' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 4, "invalid multiple 'http:Caller' parameter: 'xyz'", HTTP_115);
        assertError(diagnosticResult, 5, "incompatible respond method argument type : expected " +
                "'Person' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 6, "incompatible respond method argument type : expected " +
                "'Person' according to the 'http:CallerInfo' annotation", HTTP_114);
    }

    @Test
    public void testCallerInfoTypes() {
        Package currentPackage = loadPackage("sample_package_11");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 10);
        assertError(diagnosticResult, 0, "incompatible respond method argument type : expected " +
                "'http:Response' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 1, "incompatible respond method argument type : expected " +
                "'Xml' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 2, "incompatible respond method argument type : expected " +
                "'json' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 3, "incompatible respond method argument type : expected " +
                "'ByteArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 4, "incompatible respond method argument type : expected " +
                "'MapJson' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 5, "incompatible respond method argument type : expected " +
                "'PersonTable' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 6, "incompatible respond method argument type : expected " +
                "'MapJsonArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 7, "incompatible respond method argument type : expected " +
                "'PersonTableArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 8, "incompatible respond method argument type : expected " +
                "'EntityArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 9, "incompatible respond method argument type : expected " +
                "'ByteStream' according to the 'http:CallerInfo' annotation", HTTP_114);
    }

    @Test
    public void testInValidMultipleObjectArgs() {
        Package currentPackage = loadPackage("sample_package_12");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 6);
        assertTrue(diagnosticResult, 0, "invalid multiple 'http:Caller' parameter: 'xyz'", HTTP_115);
        assertTrue(diagnosticResult, 1, "invalid multiple 'http:Headers' parameter: 'noo'", HTTP_117);
        assertTrue(diagnosticResult, 2, "invalid multiple 'http:Request' parameter: 'aaa'", HTTP_116);
        assertTrue(diagnosticResult, 3, "invalid multiple 'http:Caller' parameter: 'ccc'", HTTP_115);
        assertTrue(diagnosticResult, 4, "invalid multiple 'http:Request' parameter: 'fwdw'", HTTP_116);
        assertTrue(diagnosticResult, 5, "invalid multiple 'http:Headers' parameter: 'ccc'", HTTP_117);
    }

    @Test
    public void testInvalidReturnTypeWithHttpCaller() {
        Package currentPackage = loadPackage("sample_package_13");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 1);
        assertTrue(diagnosticResult, 0,
                "could not use http:Caller and return 'http:BadRequest' from a resource", HTTP_118);
    }
}
