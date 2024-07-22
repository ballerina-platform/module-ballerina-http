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

import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_102;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_106;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_108;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_109;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_110;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_111;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_112;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_113;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_114;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_115;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_118;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_125;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_127;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_129;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_132;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_134;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_135;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_140;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_144;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_145;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_146;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_147;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_148;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_149;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_150;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_151;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_152;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_153;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_154;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_155;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_156;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_157;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_158;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_159;
import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.HTTP_160;

/**
 * This class includes tests for Ballerina Http compiler plugin.
 */
public class CompilerPluginTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

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
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.errors().toArray()[index];
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(), message);
        if (code != null) {
            Assert.assertEquals(diagnostic.diagnosticInfo().code(), code);
        }
    }

    private void assertTrue(DiagnosticResult diagnosticResult, int index, String message, String code) {
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.errors().toArray()[index];
        Assert.assertTrue(diagnostic.diagnosticInfo().messageFormat().contains(message));
        Assert.assertEquals(diagnostic.diagnosticInfo().code(), code);
    }

    private void assertErrorPosition(DiagnosticResult diagnosticResult, int index, String lineRange) {
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.errors().toArray()[index];
        Assert.assertEquals(diagnostic.location().lineRange().toString(), lineRange);
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
                Assert.assertEquals(result.diagnosticInfo().code(), CompilerPluginTestConstants.HTTP_101);
            }
        });
    }

    @Test
    public void testInValidReturnTypes() {
        Package currentPackage = loadPackage("sample_package_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 3);
        assertError(diagnosticResult, 0, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'error[]'", HTTP_102);
        assertError(diagnosticResult, 1, "invalid resource method return type: expected 'anydata|http:Response" +
                "|http:StatusCodeResponse|error', but found 'map<http:Client>'", HTTP_102);
        assertError(diagnosticResult, 2, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'readonly & error[]'", HTTP_102);
    }

    @Test
    public void testInValidInputPayloadArgs() {
        Package currentPackage = loadPackage("sample_package_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        assertError(diagnosticResult, 0, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Header', 'http:Query'", HTTP_108);
        assertError(diagnosticResult, 1, "invalid usage of payload annotation for a non entity body " +
                "resource : 'get'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 2, "invalid usage of payload annotation for a non entity body " +
                "resource : 'head'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 3, "invalid usage of payload annotation for a non entity body resource" +
                " : 'options'. Use an accessor that supports entity body", HTTP_129);
        assertTrue(diagnosticResult, 4, "invalid payload parameter type: 'string|ballerina/http:",
                CompilerPluginTestConstants.HTTP_107);
        assertTrue(diagnosticResult, 5, "invalid payload parameter type:",
                CompilerPluginTestConstants.HTTP_107);
        assertTrue(diagnosticResult, 6, "invalid payload parameter type:",
                CompilerPluginTestConstants.HTTP_107);
    }

    @Test
    public void testInValidInputHeaderArgs() {
        Package currentPackage = loadPackage("sample_package_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 13);
        assertError(diagnosticResult, 0, "invalid union type of header param 'xRate': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which" +
                " consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 1, "invalid type of header param 'abc': expected one of the following types is " +
                "expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 2, "invalid type of header param 'abc': expected one of the following types is " +
                "expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 3, "invalid union type of header param 'abc': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which" +
                " consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 4, "rest fields are not allowed for header binding records. Use " +
                "'http:Headers' type to access all headers", HTTP_144);
        assertError(diagnosticResult, 5, "rest fields are not allowed for header binding records. Use " +
                "'http:Headers' type to access all headers", HTTP_144);
        assertError(diagnosticResult, 6, "invalid type of header param 'abc': expected one of the following types" +
                " is expected: 'string','int','float','decimal','boolean', an array of the above types or a record " +
                "which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 7, "invalid multiple resource parameter annotations for 'abc': expected" +
                " one of the following types: 'http:Payload', 'http:CallerInfo', 'http:Header', 'http:Query'",
                HTTP_108);
        assertError(diagnosticResult, 8, "invalid type of header param 'abc': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or " +
                "a record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 9, "invalid union type of header param 'abc': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which" +
                " consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 10, "invalid type of header param 'abc': expected one of the " +
                "following types is expected: 'string','int','float','decimal','boolean', an array of the above types" +
                " or a record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 11, "invalid union type of header param 'abc': expected one of" +
                " the 'string','int','float','decimal','boolean' types, an array of the above types or a record which" +
                " consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 12, "invalid type of header param 'xRate': expected one of the" +
                " following types is expected: 'string','int','float','decimal','boolean', an array of the above " +
                "types or a record which consists of the above types", HTTP_109);
    }

    @Test
    public void testInValidCallerInfoArgs() {
        Package currentPackage = loadPackage("sample_package_6");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        String expectedMsg = "invalid resource method return type: can not use 'http:Caller' " +
                "and return 'string' from a resource : expected 'error' or nil";
        assertTrue(diagnosticResult, 0, expectedMsg, HTTP_118);
        assertError(diagnosticResult, 1, "invalid type of caller param 'abc': expected 'http:Caller'",
                HTTP_111);
        assertError(diagnosticResult, 2, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Header', 'http:Query'", HTTP_108);
        assertTrue(diagnosticResult, 3, expectedMsg, HTTP_118);
        assertError(diagnosticResult, 4, "invalid type of caller param 'abc': expected 'http:Caller'",
                HTTP_111);
    }

    @Test
    public void testInValidNonAnnotatedArgs() {
        Package currentPackage = loadPackage("sample_package_7");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        assertTrue(diagnosticResult, 0, "invalid resource method return type: can not use " +
                "'http:Caller' and return 'string' from a resource : expected 'error' or nil", HTTP_118);
        assertTrue(diagnosticResult, 1, "invalid resource parameter type: 'ballerina/http", HTTP_106);
        assertTrue(diagnosticResult, 2, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertTrue(diagnosticResult, 3, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertError(diagnosticResult, 4, "invalid resource parameter type: 'http_test/sample_7:0.1.0:Caller'",
                HTTP_106);
    }

    @Test
    public void testInValidQueryInfoArgs() {
        Package currentPackage = loadPackage("sample_package_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 9);
        assertTrue(diagnosticResult, 0, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertError(diagnosticResult, 1, "invalid union type of query param 'a': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union" +
                " with '()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 2, "invalid union type of query param 'b': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union" +
                " with '()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 3, "invalid union type of query param 'c': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union" +
                " with '()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 4, "invalid type of query param 'd': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 5, "invalid type of query param 'a': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 6, "invalid type of query param 'aa': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 7, "invalid type of query param 'd': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 8, "invalid type of query param 'e': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them",
                HTTP_112);
    }

    @Test
    public void testListenerTypes() {
        Package currentPackage = loadPackage("sample_package_9");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 2);
        diagnosticResult.diagnostics().stream().filter(err -> err.diagnosticInfo().code().contains(HTTP_106)).map(
                err -> err.diagnosticInfo().messageFormat().contains(
                        "invalid resource parameter type: 'ballerina/http")).forEach(Assert::assertTrue);
    }

    @Test
    public void testCallerInfoAnnotation() {
        Package currentPackage = loadPackage("sample_package_10");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 11);
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
        assertError(diagnosticResult, 7, "incompatible respond method argument type : expected " +
                "'Person' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 8, "incompatible respond method argument type : expected " +
                "'http:Error' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 9, "incompatible respond method argument type : expected " +
                "'http:Ok' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 10, "incompatible respond method argument type : expected " +
                "'http:StatusCodeResponse' according to the 'http:CallerInfo' annotation", HTTP_114);
    }


    @Test
    public void testCallerInfoAnnotationWithError() {
        Package currentPackage = loadPackage("sample_package_24");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 5);
        // These are the errors returned from language compiler, so skipped the codes
        assertError(diagnosticResult, 0, "incompatible.types", null);
        assertError(diagnosticResult, 1, "error.constructor.compatible.type.not.found", null);
    }

    @Test
    public void testCallerInfoTypes() {
        Package currentPackage = loadPackage("sample_package_11");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 11);
        assertError(diagnosticResult, 0, "incompatible respond method argument type : expected " +
                "'http:Response' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 1, "incompatible respond method argument type : expected " +
                "'Xml' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 2, "incompatible respond method argument type : expected " +
                "'json' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 3, "incompatible respond method argument type : expected " +
                "'json' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 4, "incompatible respond method argument type : expected " +
                "'ByteArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 5, "incompatible respond method argument type : expected " +
                "'MapJson' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 6, "incompatible respond method argument type : expected " +
                "'PersonTable' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 7, "incompatible respond method argument type : expected " +
                "'MapJsonArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 8, "incompatible respond method argument type : expected " +
                "'PersonTableArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 9, "incompatible respond method argument type : expected " +
                "'EntityArr' according to the 'http:CallerInfo' annotation", HTTP_114);
        assertError(diagnosticResult, 10, "incompatible respond method argument type : expected " +
                "'ByteStream' according to the 'http:CallerInfo' annotation", HTTP_114);
    }

    @Test
    public void testInValidMultipleObjectArgs() {
        Package currentPackage = loadPackage("sample_package_12");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 6);
        assertTrue(diagnosticResult, 0, "invalid multiple 'http:Caller' parameter: 'xyz'", HTTP_115);
        assertTrue(diagnosticResult, 1, "invalid multiple 'http:Headers' parameter: 'noo'",
                CompilerPluginTestConstants.HTTP_117);
        assertTrue(diagnosticResult, 2, "invalid multiple 'http:Request' parameter: 'aaa'",
                CompilerPluginTestConstants.HTTP_116);
        assertTrue(diagnosticResult, 3, "invalid multiple 'http:Caller' parameter: 'ccc'", HTTP_115);
        assertTrue(diagnosticResult, 4, "invalid multiple 'http:Request' parameter: 'fwdw'",
                CompilerPluginTestConstants.HTTP_116);
        assertTrue(diagnosticResult, 5, "invalid multiple 'http:Headers' parameter: 'ccc'",
                CompilerPluginTestConstants.HTTP_117);
    }

    @Test
    public void testInvalidReturnTypeWithHttpCaller() {
        Package currentPackage = loadPackage("sample_package_13");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        String expectedMsg = "invalid resource method return type: can not use 'http:Caller' " +
                "and return 'http:BadRequest?' from a resource : expected 'error' or nil";
        assertTrue(diagnosticResult, 0, expectedMsg, HTTP_118);
    }

    @Test
    public void testInvalidMediaTypeSubtypePrefix() {
        Package currentPackage = loadPackage("sample_package_14");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        assertError(diagnosticResult, 0, "invalid media-type subtype prefix: subtype prefix should not " +
                "have suffix 'suffix'", CompilerPluginTestConstants.HTTP_119);
        assertError(diagnosticResult, 1, "invalid media-type subtype prefix: subtype prefix should not " +
                "have suffix 'suffix1 + suffix2'", CompilerPluginTestConstants.HTTP_119);
        assertError(diagnosticResult, 2, "invalid media-type subtype '+suffix'",
                CompilerPluginTestConstants.HTTP_120);
        assertError(diagnosticResult, 3, "invalid media-type subtype 'vnd.prefix.subtype+'",
                CompilerPluginTestConstants.HTTP_120);
    }

    @Test
    public void testResourceErrorPositions() {
        Package currentPackage = loadPackage("sample_package_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 12);
        // only testing the error locations
        assertErrorPosition(diagnosticResult, 0, "(29:44,29:60)");
        assertErrorPosition(diagnosticResult, 1, "(46:57,46:60)");
        assertErrorPosition(diagnosticResult, 2, "(50:63,50:66)");
        assertErrorPosition(diagnosticResult, 3, "(54:66,54:69)");
        assertErrorPosition(diagnosticResult, 4, "(58:77,58:80)");
        assertErrorPosition(diagnosticResult, 5, "(62:76,62:79)");
        assertErrorPosition(diagnosticResult, 6, "(66:76,66:82)");
        assertErrorPosition(diagnosticResult, 7, "(73:45,73:46)");
        assertErrorPosition(diagnosticResult, 8, "(81:43,81:46)");
        assertErrorPosition(diagnosticResult, 9, "(81:61,81:64)");
        assertErrorPosition(diagnosticResult, 10, "(81:79,81:82)");
        assertErrorPosition(diagnosticResult, 11, "(85:77,85:93)");
    }

    @Test
    public void testMultipleSameAnnotations() {
        Package currentPackage = loadPackage("sample_package_16");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.errors().toArray()[0];
        Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(),
                            "annotation.attachment.cannot.specify.multiple.values");
    }

    @Test
    public void testRequestContextParam() {
        Package currentPackage = loadPackage("sample_package_17");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        assertError(diagnosticResult, 0, "invalid multiple 'http:RequestContext' parameter: 'bcd'",
                CompilerPluginTestConstants.HTTP_121);
    }

    @Test
    public void testErrorParam() {
        Package currentPackage = loadPackage("sample_package_18");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        assertError(diagnosticResult, 0, "invalid multiple 'error' parameter: 'bcd'",
                CompilerPluginTestConstants.HTTP_122);
    }

    @Test
    public void testInterceptorServiceObject() {
        Package currentPackage = loadPackage("sample_package_19");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 30);
        assertError(diagnosticResult, 0, "invalid multiple interceptor type reference: " +
                "'http:RequestErrorInterceptor'", CompilerPluginTestConstants.HTTP_123);
        assertError(diagnosticResult, 1, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found 'foo'", HTTP_127);
        assertError(diagnosticResult, 2, "invalid interceptor resource method: expected default " +
                "resource method: 'default', but found 'get'", CompilerPluginTestConstants.HTTP_128);
        assertError(diagnosticResult, 3, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found 'foo'", HTTP_127);
        assertError(diagnosticResult, 4, "invalid interceptor resource method: expected default " +
                "resource method: 'default', but found 'get'", CompilerPluginTestConstants.HTTP_128);
        assertError(diagnosticResult, 5, "invalid interceptor resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|http:NextService|error?', but found 'error[]'",
                CompilerPluginTestConstants.HTTP_126);
        assertError(diagnosticResult, 6, "invalid multiple interceptor resource functions",
                CompilerPluginTestConstants.HTTP_124);
        assertError(diagnosticResult, 7, "invalid annotation 'http:ResourceConfig': annotations" +
                " are not supported for interceptor resource functions", HTTP_125);
        assertError(diagnosticResult, 8, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found '[string path]'", HTTP_127);
        assertError(diagnosticResult, 9, "resource function should have the mandatory parameter 'error'",
                CompilerPluginTestConstants.HTTP_143);
        assertError(diagnosticResult, 10, "invalid usage of payload annotation for a non entity body " +
                "resource : 'get'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 11, "RequestInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 12, "RequestErrorInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 13, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 14, "remote function is not allowed in RequestInterceptor",
                CompilerPluginTestConstants.HTTP_137);
        assertError(diagnosticResult, 15, "RequestInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 16, "remote function is not allowed in RequestErrorInterceptor",
                CompilerPluginTestConstants.HTTP_137);
        assertError(diagnosticResult, 17, "RequestErrorInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 18, "resource function is not allowed in ResponseInterceptor",
                CompilerPluginTestConstants.HTTP_136);
        assertError(diagnosticResult, 19, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 20, "invalid remote function : 'returnResponse'. ResponseInterceptor " +
                "can have only 'interceptResponse' remote function", CompilerPluginTestConstants.HTTP_138);
        assertError(diagnosticResult, 21, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 22, "invalid multiple 'http:Response' parameter: 'res2'",
                CompilerPluginTestConstants.HTTP_139);
        assertError(diagnosticResult, 23, "invalid parameter type: 'string' in 'interceptResponse' remote method",
                HTTP_140);
        assertError(diagnosticResult, 24, "invalid interceptor remote method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|http:NextService|error?', but found 'http:Client'",
                CompilerPluginTestConstants.HTTP_141);
        assertError(diagnosticResult, 25, "return type annotation is not supported in interceptor service",
                CompilerPluginTestConstants.HTTP_142);
        assertError(diagnosticResult, 26, "return type annotation is not supported in interceptor service",
                CompilerPluginTestConstants.HTTP_142);
        assertError(diagnosticResult, 27, "invalid remote function : 'interceptError'. ResponseErrorInterceptor " +
                "can have only 'interceptResponseError' remote function", CompilerPluginTestConstants.HTTP_138);
        assertError(diagnosticResult, 28, "ResponseErrorInterceptor must have the remote method : " +
                "'interceptResponseError'", HTTP_135);
        assertError(diagnosticResult, 29, "remote function should have the mandatory parameter 'error'",
                CompilerPluginTestConstants.HTTP_143);
    }

    @Test
    public void testReadonlyReturnTypes() {
        Package currentPackage = loadPackage("sample_package_20");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testReadonlyParameterTypes() {
        Package currentPackage = loadPackage("sample_package_21");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testAnnotationUsageWithReturnType() {
        Package currentPackage = loadPackage("sample_package_22");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        assertError(diagnosticResult, 0, "invalid usage of cache annotation with return type : " +
                "'error'. Cache annotation only supports return types of anydata and SuccessStatusCodeResponse",
                CompilerPluginTestConstants.HTTP_130);
        assertError(diagnosticResult, 1, "invalid usage of payload annotation with return type : " +
                "'error'", CompilerPluginTestConstants.HTTP_131);
        assertError(diagnosticResult, 2, "invalid usage of payload annotation with return type : " +
                "'error?'", CompilerPluginTestConstants.HTTP_131);
        assertError(diagnosticResult, 3, "invalid usage of cache annotation with return type : " +
                "'error?'. Cache annotation only supports return types of anydata and SuccessStatusCodeResponse",
                CompilerPluginTestConstants.HTTP_130);
    }

    @Test
    public void testInValidIntersectionTypeForResourceArgs() {
        Package currentPackage = loadPackage("sample_package_23");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 6);
        assertTrue(diagnosticResult, 0, "'readonly' intersection type is not allowed for parameter 'caller' of the " +
                "type 'ballerina/http:", HTTP_134);
        assertTrue(diagnosticResult, 0, ":Caller & readonly'", HTTP_134);
        assertTrue(diagnosticResult, 1, "'readonly' intersection type is not allowed for parameter 'request' of the " +
                "type 'ballerina/http:", HTTP_134);
        assertTrue(diagnosticResult, 2, "'readonly' intersection type is not allowed for parameter 'headers' of the " +
                "type 'ballerina/http:", HTTP_134);
        assertTrue(diagnosticResult, 3, "'readonly' intersection type is not allowed for parameter 'entity' of the " +
                "type 'ballerina/mime:", HTTP_134);
        assertTrue(diagnosticResult, 3, ":Entity & readonly'", HTTP_134);
        assertTrue(diagnosticResult, 4, "invalid type of header param 'host': expected one of the following types is " +
                "expected: 'string','int','float','decimal','boolean', an array of the above types or a record " +
                "which consists of the above types", HTTP_109);
        assertTrue(diagnosticResult, 5, "invalid type of caller param 'host': expected 'http:Caller'", HTTP_111);
    }

    @Test
    public void testLinksInResources() {
        Package currentPackage = loadPackage("sample_package_25");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        assertTrue(diagnosticResult, 0, "duplicate link relation: 'self'. Resource only supports unique relations",
                HTTP_147);
        assertTrue(diagnosticResult, 1, "duplicate link relation: 'self'. Resource only supports unique relations",
                HTTP_147);
        assertTrue(diagnosticResult, 2, "resource link name: 'resource1' conflicts with the path. Resource names can " +
                "be reused only when the resources have the same path", HTTP_146);
        assertTrue(diagnosticResult, 3, "duplicate link relation: 'add'. Resource only supports unique relations",
                HTTP_147);
        assertTrue(diagnosticResult, 4, "resource link name: 'resource3' conflicts with the path. Resource names can " +
                "be reused only when the resources have the same path", HTTP_146);
        assertTrue(diagnosticResult, 5, "cannot find resource with resource link name: 'resource5'", HTTP_148);
        assertTrue(diagnosticResult, 6, "cannot find 'POST' resource with resource link name: 'resource1'", HTTP_150);
        assertTrue(diagnosticResult, 7, "cannot resolve linked resource without method", HTTP_149);
    }

    @Test
    public void testRecursiveRecordDefinitionsAsPayload() {
        Package currentPackage = loadPackage("sample_package_26");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testRecursiveRecordDefinitionsAsReturnType() {
        Package currentPackage = loadPackage("sample_package_27");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testAnydataUnionTypeAsReturnType() {
        Package currentPackage = loadPackage("sample_package_28");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testInvalidUnionTypesAsReturnType() {
        Package currentPackage = loadPackage("sample_package_29");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 9);
        assertTrue(diagnosticResult, 0, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord1[]'", HTTP_102);
        assertTrue(diagnosticResult, 1, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord2[]'", HTTP_102);
        assertTrue(diagnosticResult, 2, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord3[]'", HTTP_102);
        assertTrue(diagnosticResult, 3, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord4[]'", HTTP_102);
        assertTrue(diagnosticResult, 4, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord5[]'", HTTP_102);
        assertTrue(diagnosticResult, 5, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord6[]'", HTTP_102);
        assertTrue(diagnosticResult, 6, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'TestRecord7[]'", HTTP_102);
        assertTrue(diagnosticResult, 7, "invalid resource method return type: expected 'anydata|" +
                "http:Response|http:StatusCodeResponse|error', but found 'http:StatusCodeResponse[]'", HTTP_102);
        assertTrue(diagnosticResult, 8, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeResponse|error', but found 'error[]'", HTTP_102);
    }

    @Test
    public void testEnumTypeAsQueryParameter() {
        Package currentPackage = loadPackage("sample_package_30");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testRecursiveRecordDefinitionsWithUnionsAsPayload() {
        Package currentPackage = loadPackage("sample_package_31");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testRecursiveRecordDefinitionsWithReadonlyIntersectionAsPayload() {
        Package currentPackage = loadPackage("sample_package_32");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();
        Assert.assertEquals(availableErrors, 0);
    }

    @Test
    public void testCodeModifierPayloadAnnotation() {
        Package currentPackage = loadPackage("sample_package_33");
        DiagnosticResult modifierDiagnosticResult = currentPackage.runCodeGenAndModifyPlugins();
        Assert.assertEquals(modifierDiagnosticResult.errorCount(), 0);
    }

    @Test
    public void testQueryAnnotation() {
        Package currentPackage = loadPackage("sample_package_34");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 12);
    }

    @Test
    public void testCodeModifierErrorTest() {
        Package currentPackage = loadPackage("sample_package_35");
        // This is not working if we do not report diagnostics from the code modifier
        // DiagnosticResult modifierDiagnosticResult = currentPackage.runCodeGenAndModifyPlugins();
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult modifierDiagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(modifierDiagnosticResult.errorCount(), 10);
        assertTrue(modifierDiagnosticResult, 0, "ambiguous types for parameter 'a' and 'b'. Use " +
                "annotations to avoid ambiguity", HTTP_151);
        assertTrue(modifierDiagnosticResult, 1, "ambiguous types for parameter 'c' and 'd'. Use " +
                "annotations to avoid ambiguity", HTTP_151);
        assertTrue(modifierDiagnosticResult, 2, "ambiguous types for parameter 'e' and 'f'. Use " +
                "annotations to avoid ambiguity", HTTP_151);
        assertTrue(modifierDiagnosticResult, 3, "invalid union type for default payload param: 'g'. " +
                "Use basic structured anydata types", HTTP_152);
        assertError(modifierDiagnosticResult, 4, "invalid multiple resource parameter annotations for" +
                " 'g': expected one of the following types: 'http:Payload', 'http:CallerInfo', 'http:Header'," +
                " 'http:Query'", HTTP_108);
        assertTrue(modifierDiagnosticResult, 5, "invalid resource parameter type", HTTP_106);
        assertTrue(modifierDiagnosticResult, 6, "ambiguous types for parameter 'q' and 'p'. Use " +
                "annotations to avoid ambiguity", HTTP_151);
        assertTrue(modifierDiagnosticResult, 7, "invalid resource parameter type", HTTP_106);
        assertTrue(modifierDiagnosticResult, 8, "invalid resource parameter type", HTTP_106);
        assertTrue(modifierDiagnosticResult, 9, "invalid union type for default payload param: 'a'. " +
                "Use basic structured anydata types", HTTP_152);
    }

    @Test
    public void testCodeModifierWithServiceClassesPayloadAnnotation() {
        Package currentPackage = loadPackage("sample_package_36");
        DiagnosticResult modifierDiagnosticResult = currentPackage.runCodeGenAndModifyPlugins();
        Assert.assertEquals(modifierDiagnosticResult.errorCount(), 0);
    }

    @Test
    public void testPathParameterType() {
        Package currentPackage = loadPackage("sample_package_37");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        assertError(diagnosticResult, 0, "invalid resource path parameter 'path1': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 1, "invalid resource path parameter 'path2': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 2, "invalid resource path parameter 'path3': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 3, "invalid resource path parameter 'path4': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 4, "invalid resource path parameter 'path5': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 5, "invalid resource path parameter 'path6': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 6, "invalid resource path parameter 'path7': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
        assertError(diagnosticResult, 7, "invalid resource path parameter 'id': expected one of the" +
                " 'string','int','float','decimal','boolean' types or a rest parameter with one of the above types",
                HTTP_145);
    }

    @Test
    public void testResourceSignatureParamValidations() {
        Package currentPackage = loadPackage("sample_package_38");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 36);
        assertError(diagnosticResult, 0, "invalid union type of header param 'header': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 1, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 2, "invalid union type of header param 'header': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 3, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 4, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 5, "invalid union type of header param 'header': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 6, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 7, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 8, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 9, "invalid type of header param 'header': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 10, "invalid union type of header param 'header': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 11, "invalid union type of header param 'header1': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 12, "invalid type of header param 'header2': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 13, "invalid union type of header param 'header3': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 14, "invalid type of header param 'header4': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 15, "invalid type of header param 'header5': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 16, "invalid union type of header param 'header6': expected one of the" +
                " 'string','int','float','decimal','boolean' types, an array of the above types or a record which " +
                "consists of the above types can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 17, "invalid type of header param 'header7': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 18, "invalid type of header param 'header9': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 19, "invalid type of header param 'header10': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 20, "invalid type of header param 'header12': expected one of the following" +
                " types is expected: 'string','int','float','decimal','boolean', an array of the above types or a " +
                "record which consists of the above types", HTTP_109);
        assertError(diagnosticResult, 21, "invalid resource path parameter 'path': expected one of the 'string'," +
                "'int','float','decimal','boolean' types or a rest parameter with one of the above types", HTTP_145);
        assertError(diagnosticResult, 22, "invalid resource path parameter 'path': expected one of the 'string'," +
                "'int','float','decimal','boolean' types or a rest parameter with one of the above types", HTTP_145);
        assertError(diagnosticResult, 23, "invalid resource path parameter 'path': expected one of the 'string'," +
                "'int','float','decimal','boolean' types or a rest parameter with one of the above types", HTTP_145);
        assertError(diagnosticResult, 24, "invalid union type of query param 'query': 'string', 'int', 'float', " +
                "'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union with '()'." +
                " Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 25, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 26, "invalid union type of query param 'query': 'string', 'int', 'float'," +
                " 'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union with '()'." +
                " Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 27, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 28, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 29, "invalid union type of query param 'query': 'string', 'int', 'float'," +
                " 'boolean', 'decimal', 'map<anydata>' type or the array types of them can only be union with '()'." +
                " Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 30, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 31, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 32, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 33, "invalid type of query param 'query': expected one of the 'string'," +
                " 'int', 'float', 'boolean', 'decimal', 'map<anydata>' types or the array types of them", HTTP_112);
        assertError(diagnosticResult, 34, "invalid resource parameter type: " +
                "'http_test/sample_38:0.1.0:QueryRecordCombinedInvalid?'", HTTP_106);
        assertError(diagnosticResult, 35, "invalid resource parameter type: " +
                "'(http_test/sample_38:0.1.0:QueryRecord|map<any>)[]?'", HTTP_106);
    }

    @Test
    public void testInterceptableServiceInterceptors() {
        Package currentPackage = loadPackage("sample_package_39");
        PackageCompilation packageCompilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = packageCompilation.diagnosticResult();
        Assert.assertFalse(diagnosticResult.hasWarnings());
        Assert.assertFalse(diagnosticResult.hasErrors());
    }

    @Test
    public void testServiceContractValidations() {
        Package currentPackage = loadPackage("sample_package_40");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 8);
        assertError(diagnosticResult, 0, "base path not allowed in the service declaration which is" +
                " implemented via the 'http:ServiceContract' type. The base path is inferred from the service " +
                "contract type", HTTP_154);
        assertError(diagnosticResult, 1, "'http:ServiceConfig' annotation is not allowed for service " +
                "declaration implemented via the 'http:ServiceContract' type. The HTTP annotations are inferred" +
                " from the service contract type", HTTP_153);
        assertError(diagnosticResult, 2, "configuring base path in the 'http:ServiceConfig' annotation" +
                " is not allowed for non service contract types", HTTP_155);
        assertError(diagnosticResult, 3, "invalid service type descriptor found in 'http:ServiceConfig' " +
                "annotation. Expected service type: 'ContractService' but found: 'ContractServiceWithoutServiceConfig'",
                HTTP_156);
        assertError(diagnosticResult, 4, "'serviceType' is not allowed in the service which is not implemented" +
                " via the 'http:ServiceContract' type", HTTP_157);
        assertError(diagnosticResult, 5, "resource function which is not defined in the service contract type:" +
                " 'ContractServiceWithResource', is not allowed", HTTP_158);
        assertError(diagnosticResult, 6, "'http:ResourceConfig' annotation is not allowed for resource function " +
                "implemented via the 'http:ServiceContract' type. The HTTP annotations are inferred from the service" +
                " contract type", HTTP_159);
        assertError(diagnosticResult, 7, "'http:Header' annotation is not allowed for resource function implemented" +
                " via the 'http:ServiceContract' type. The HTTP annotations are inferred from the service contract" +
                " type", HTTP_160);
    }
}
