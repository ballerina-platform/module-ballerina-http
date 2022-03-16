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

import static io.ballerina.stdlib.http.compiler.CompilerPluginTestConstants.*;

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
        Assert.assertEquals(diagnostic.diagnosticInfo().code(), code);
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
                Assert.assertEquals(result.diagnosticInfo().code(), HTTP_101);
            }
        });
    }

    @Test
    public void testInValidReturnTypes() {
        Package currentPackage = loadPackage("sample_package_2");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 4);
        assertError(diagnosticResult, 0, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|error', but found 'http:Client'", HTTP_102);
        assertError(diagnosticResult, 1, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|error', but found 'error[]'", HTTP_102);
        assertError(diagnosticResult, 2, "invalid resource method return type: expected 'anydata|http:Response" +
                "|http:StatusCodeRecord|error', but found 'map<http:Client>'", HTTP_102);
        assertError(diagnosticResult, 3, "invalid resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|error', but found 'readonly & error[]'", HTTP_102);
    }

    @Test
    public void testInValidAnnotations() {
        Package currentPackage = loadPackage("sample_package_3");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        assertError(diagnosticResult, 0, "invalid resource method annotation type: expected 'http:ResourceConfig', " +
                "but found 'test:Config '", HTTP_103);
    }

    @Test
    public void testInValidInputPayloadArgs() {
        Package currentPackage = loadPackage("sample_package_4");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 11);
        assertError(diagnosticResult, 0, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
        assertError(diagnosticResult, 1, "invalid usage of payload annotation for a non entity body " +
                "resource : 'get'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 2, "invalid usage of payload annotation for a non entity body " +
                "resource : 'head'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 3, "invalid usage of payload annotation for a non entity body resource" +
                " : 'options'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 4, "invalid payload parameter type: 'json[]'", HTTP_107);
        assertError(diagnosticResult, 5, "invalid annotation type on param 'a': expected one of the following types: " +
                "'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_104);
        assertError(diagnosticResult, 6, "invalid resource parameter type: " +
                "'table<http_test/sample_4:0.1.0:Person> key(id)'", HTTP_106);
        assertError(diagnosticResult, 7, "invalid payload parameter type: 'map<int>'", HTTP_107);
        assertError(diagnosticResult, 8, "invalid payload parameter type: 'string[]'", HTTP_107);
        assertError(diagnosticResult, 9, "invalid payload parameter type: 'xml[]'", HTTP_107);
        assertError(diagnosticResult, 10, "invalid payload parameter type: 'map<string>[]'", HTTP_107);
    }

    @Test
    public void testInValidInputHeaderArgs() {
        Package currentPackage = loadPackage("sample_package_5");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
        assertError(diagnosticResult, 0, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 1, "invalid multiple resource parameter annotations for 'abc': expected one of " +
                   "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
        assertError(diagnosticResult, 2, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 3, "invalid union type of header param 'abc': a string or an array " +
                        "of a string can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 4, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
        assertError(diagnosticResult, 5, "invalid union type of header param 'abc': a string or an array" +
                " of a string can only be union with '()'. Eg: string|() or string[]|()", HTTP_110);
        assertError(diagnosticResult, 6, "invalid type of header param 'abc': expected 'string' or 'string[]'",
                    HTTP_109);
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
                "the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", HTTP_108);
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
        String expectedMsg = "invalid resource method return type: can not use 'http:Caller' " +
                "and return 'string' from a resource : expected 'error' or nil";
        assertTrue(diagnosticResult, 0, expectedMsg, HTTP_118);
        assertTrue(diagnosticResult, 1, "invalid resource parameter type: 'ballerina/http", HTTP_106);
        assertTrue(diagnosticResult, 2, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertTrue(diagnosticResult, 3, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertTrue(diagnosticResult, 4, "invalid resource parameter type: 'http_test/sample_7", HTTP_106);
    }

    @Test
    public void testInValidQueryInfoArgs() {
        Package currentPackage = loadPackage("sample_package_8");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 12);
        assertTrue(diagnosticResult, 0, "invalid resource parameter type: 'ballerina/mime", HTTP_106);
        assertError(diagnosticResult, 1, "invalid union type of query param 'a': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<json>' type or the array types of them can only be union with " +
                "'()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 2, "invalid union type of query param 'b': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<json>' type or the array types of them can only be union with " +
                "'()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 3, "invalid union type of query param 'c': 'string', 'int', " +
                "'float', 'boolean', 'decimal', 'map<json>' type or the array types of them can only be union with " +
                "'()'. Eg: string? or int[]?", HTTP_113);
        assertError(diagnosticResult, 4, "invalid type of query param 'd': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertTrue(diagnosticResult, 5, "invalid resource parameter type: 'json'",
                HTTP_106);
        assertError(diagnosticResult, 6, "invalid type of query param 'aa': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 7, "invalid type of query param 'a': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 8, "invalid type of query param 'b': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 9, "invalid type of query param 'c': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertError(diagnosticResult, 10, "invalid type of query param 'd': expected one of the " +
                "'string', 'int', 'float', 'boolean', 'decimal', 'map<json>' types or the array types of them",
                HTTP_112);
        assertTrue(diagnosticResult, 11, "invalid resource parameter type: 'xml'", HTTP_106);
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
        Assert.assertEquals(diagnosticResult.errorCount(), 7);
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
        Assert.assertEquals(diagnosticResult.errorCount(), 10);
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
        Assert.assertEquals(diagnosticResult.errorCount(), 6);
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
                "have suffix 'suffix'", HTTP_119);
        assertError(diagnosticResult, 1, "invalid media-type subtype prefix: subtype prefix should not " +
                "have suffix 'suffix1 + suffix2'", HTTP_119);
        assertError(diagnosticResult, 2, "invalid media-type subtype '+suffix'", HTTP_120);
        assertError(diagnosticResult, 3, "invalid media-type subtype 'vnd.prefix.subtype+'", HTTP_120);
    }

    @Test
    public void testResourceErrorPositions() {
        Package currentPackage = loadPackage("sample_package_15");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 15);
        // only testing the error locations
        assertErrorPosition(diagnosticResult, 0, "(30:44,30:60)");
        assertErrorPosition(diagnosticResult, 1, "(35:5,35:16)");
        assertErrorPosition(diagnosticResult, 2, "(40:86,40:87)");
        assertErrorPosition(diagnosticResult, 3, "(44:57,44:60)");
        assertErrorPosition(diagnosticResult, 4, "(48:56,48:59)");
        assertErrorPosition(diagnosticResult, 5, "(52:66,52:69)");
        assertErrorPosition(diagnosticResult, 6, "(56:77,56:80)");
        assertErrorPosition(diagnosticResult, 7, "(60:76,60:79)");
        assertErrorPosition(diagnosticResult, 8, "(64:76,64:82)");
        assertErrorPosition(diagnosticResult, 9, "(68:47,68:48)");
        assertErrorPosition(diagnosticResult, 10, "(71:45,71:46)");
        assertErrorPosition(diagnosticResult, 11, "(79:43,79:46)");
        assertErrorPosition(diagnosticResult, 12, "(79:61,79:64)");
        assertErrorPosition(diagnosticResult, 13, "(79:79,79:82)");
        assertErrorPosition(diagnosticResult, 14, "(83:77,83:93)");
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
        assertError(diagnosticResult, 0, "invalid multiple 'http:RequestContext' parameter: 'bcd'", HTTP_121);
    }

    @Test
    public void testErrorParam() {
        Package currentPackage = loadPackage("sample_package_18");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 1);
        assertError(diagnosticResult, 0, "invalid multiple 'error' parameter: 'bcd'", HTTP_122);
    }

    @Test
    public void testInterceptorServiceObject() {
        Package currentPackage = loadPackage("sample_package_19");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 27);
        assertError(diagnosticResult, 0, "invalid multiple interceptor type reference: " +
                "'http:RequestErrorInterceptor'", HTTP_123);
        assertError(diagnosticResult, 1, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found 'foo'", HTTP_127);
        assertError(diagnosticResult, 2, "invalid interceptor resource method: expected default " +
                "resource method: 'default', but found 'get'", HTTP_128);
        assertError(diagnosticResult, 3, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found 'foo'", HTTP_127);
        assertError(diagnosticResult, 4, "invalid interceptor resource method: expected default " +
                "resource method: 'default', but found 'get'", HTTP_128);
        assertError(diagnosticResult, 5, "invalid interceptor resource method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|http:NextService|error?', but found 'error[]'", HTTP_126);
        assertError(diagnosticResult, 6, "invalid multiple interceptor resource functions", HTTP_124);
        assertError(diagnosticResult, 7, "invalid annotation 'http:ResourceConfig': annotations" +
                " are not supported for interceptor resource functions", HTTP_125);
        assertError(diagnosticResult, 8, "invalid interceptor resource path: expected default resource" +
                " path: '[string... path]', but found '[string path]'", HTTP_127);
        assertError(diagnosticResult, 9, "invalid usage of payload annotation for a non entity body " +
                "resource : 'get'. Use an accessor that supports entity body", HTTP_129);
        assertError(diagnosticResult, 10, "RequestInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 11, "RequestErrorInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 12, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 13, "remote function is not allowed in RequestInterceptor", HTTP_137);
        assertError(diagnosticResult, 14, "RequestInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 15, "remote function is not allowed in RequestErrorInterceptor",
                HTTP_137);
        assertError(diagnosticResult, 16, "RequestErrorInterceptor must have a resource method", HTTP_132);
        assertError(diagnosticResult, 17, "resource function is not allowed in ResponseInterceptor",
                HTTP_136);
        assertError(diagnosticResult, 18, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 19, "invalid remote function : 'returnResponse'. ResponseInterceptor " +
                "can have only 'interceptResponse' remote function", HTTP_138);
        assertError(diagnosticResult, 20, "ResponseInterceptor must have the remote method : 'interceptResponse'",
                HTTP_135);
        assertError(diagnosticResult, 21, "invalid multiple 'http:Response' parameter: 'res2'", HTTP_139);
        assertTrue(diagnosticResult, 22, "invalid parameter type: 'ballerina/http:", HTTP_140);
        assertTrue(diagnosticResult, 22, ":Request' in 'interceptResponse' remote method", HTTP_140);
        assertError(diagnosticResult, 23, "invalid parameter type: 'string' in 'interceptResponse' remote method",
                HTTP_140);
        assertError(diagnosticResult, 24, "invalid interceptor remote method return type: expected " +
                "'anydata|http:Response|http:StatusCodeRecord|http:NextService|error?', but found 'http:Client'", HTTP_141);
        assertError(diagnosticResult, 25, "return type annotation is not supported in interceptor service",
                HTTP_142);
        assertError(diagnosticResult, 26, "return type annotation is not supported in interceptor service",
                HTTP_142);
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
                HTTP_130);
        assertError(diagnosticResult, 1, "invalid usage of payload annotation with return type : " +
                "'error'", HTTP_131);
        assertError(diagnosticResult, 2, "invalid usage of payload annotation with return type : " +
                "'error?'", HTTP_131);
        assertError(diagnosticResult, 3, "invalid usage of cache annotation with return type : " +
                "'error?'. Cache annotation only supports return types of anydata and SuccessStatusCodeResponse",
                HTTP_130);
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
        assertTrue(diagnosticResult, 4, "invalid type of header param 'host': expected 'string' or 'string[]'",
                HTTP_109);
        assertTrue(diagnosticResult, 5, "invalid type of caller param 'host': expected 'http:Caller'",
                HTTP_111);
    }
}
