// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;

//Test function with single header value
@test:Config {}
function testSingleHeaderValue() {
    var result = http:parseHeader(TEXT_PLAIN);
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, TEXT_PLAIN, msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
    }
}

//Test function with single header value and params
@test:Config {}
function testSingleHeaderValueWithParam() {
    var result = http:parseHeader(TEXT_PLAIN + ";a=2;b=0.9");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, TEXT_PLAIN, msg = "Found unexpected output");
        test:assertEquals(result[0].params["a"], "2", msg = "Found unexpected output");
        test:assertEquals(result[0].params["b"], "0.9", msg = "Found unexpected output");
    }
}

//Test function with multiple header values
@test:Config {}
function testMultipleHeaderValue() {
    var result = http:parseHeader(TEXT_PLAIN + " , " + APPLICATION_FORM);
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, TEXT_PLAIN, msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
        test:assertEquals(result[1].value, APPLICATION_FORM, msg = "Found unexpected output");
        test:assertEquals(result[1].params.length(), 0, msg = "Found unexpected output");
    }
}

//Test function with extra space in between values and params
@test:Config {}
function testWithExtraSpaceInBetweenParams() {
    var result = http:parseHeader(APPLICATION_JSON + " ; a = 2 ;    b  =    0.9");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, APPLICATION_JSON, msg = "Found unexpected output");
        test:assertEquals(result[0].params["a"], "2", msg = "Found unexpected output");
        test:assertEquals(result[0].params["b"], "0.9", msg = "Found unexpected output");
    }
}

//Test function with header value ends with semicolon
@test:Config {}
function testHeaderValueEndingWithSemiColon() {
    var result = http:parseHeader(APPLICATION_XML + ";");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, APPLICATION_XML, msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
    }
}

//Test function with empty header value
@test:Config {}
function testWithEmptyValue() {
    var result = http:parseHeader("");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, "", msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
    }
}

//Test function when param value is optional. i.e 'text/plain;a, application/xml'
@test:Config {}
function testValueWithOptionalParam() {
    var result = http:parseHeader(TEXT_PLAIN + ";a, " + APPLICATION_XML);
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, TEXT_PLAIN, msg = "Found unexpected output");
        test:assertEquals(result[0].params["a"], (), msg = "Found unexpected output");
        test:assertEquals(result[1].value, APPLICATION_XML, msg = "Found unexpected output");
    }
}

@test:Config {}
function testMultipleValuesWithMultipleParams() {
    var result = http:parseHeader(TEXT_PLAIN + ";a=\"hello\", " + APPLICATION_XML + ";a=2;b=0.9");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, TEXT_PLAIN, msg = "Found unexpected output");
        test:assertEquals(result[0].params["a"], "\"hello\"", msg = "Found unexpected output");
        test:assertEquals(result[1].value, APPLICATION_XML, msg = "Found unexpected output");
        test:assertEquals(result[1].params["a"], "2", msg = "Found unexpected output");
        test:assertEquals(result[1].params["b"], "0.9", msg = "Found unexpected output");
    }
}

@test:Config {}
function testCacheControlHeader() {
    var result = http:parseHeader(" must-revalidate,public,max-age=15");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, "must-revalidate", msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
        test:assertEquals(result[1].value, "public", msg = "Found unexpected output");
        test:assertEquals(result[1].params.length(), 0, msg = "Found unexpected output");
        test:assertEquals(result[2].value, "max-age=15", msg = "Found unexpected output");
        test:assertEquals(result[2].params.length(), 0, msg = "Found unexpected output");
    }
}

@test:Config {}
function testLinkHeader() {
    string linkHeader = "<https://api.github.com/repositories/73930305/stargazers?page=2>; rel=\"next\", "
                        + "<https://api.github.com/repositories/73930305/stargazers?page=98>; rel=\"last\"";
    var result = http:parseHeader(linkHeader);
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, "<https://api.github.com/repositories/73930305/stargazers?page=2>", msg = "Found unexpected output");
        test:assertEquals(result[0].params["rel"], "\"next\"", msg = "Found unexpected output");
        test:assertEquals(result[1].value, "<https://api.github.com/repositories/73930305/stargazers?page=98>", msg = "Found unexpected output");
        test:assertEquals(result[1].params["rel"], "\"last\"", msg = "Found unexpected output");
    }
}

//Test function with empty value
@test:Config {}
function testEmptyValue() {
    var result = http:parseHeader("");
    if result is error {
        test:assertFail(msg = "Found unexpected output type: " + result.message());
    } else {
        test:assertEquals(result[0].value, "", msg = "Found unexpected output");
        test:assertEquals(result[0].params.length(), 0, msg = "Found unexpected output");
    }
}

//***Negative test cases for ballerina/http parseHeader native function.

//Test function with missing header value. i.e ';a=2;b=0.9'
@test:Config {}
function testWithMissingValue() {
    var result = http:parseHeader(";a = 2");
    if result is error {
        test:assertEquals(result.message(),
            "failed to parse: error InvalidHeaderValueError (\"invalid header value: ;a = 2\")",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

//Test function with invalid param values
@test:Config {}
function testInvalidParams1() {
    var result = http:parseHeader(TEXT_PLAIN + ";a = ");
    if result is error {
        test:assertEquals(result.message(),
            "failed to parse: error InvalidHeaderParamError (\"invalid header parameter: a =\")",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

//Test function with invalid param values
@test:Config {}
function testInvalidParams2() {
    var result = http:parseHeader(TEXT_PLAIN + "; = ");
    if result is error {
        test:assertEquals(result.message(),
            "failed to parse: error InvalidHeaderParamError (\"invalid header parameter: =\")",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

//Test function with invalid param values
@test:Config {}
function testInvalidParams3() {
    var result = http:parseHeader(TEXT_PLAIN + "; = 2");
    if result is error {
        test:assertEquals(result.message(),
            "failed to parse: error InvalidHeaderParamError (\"invalid header parameter: = 2\")",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}
