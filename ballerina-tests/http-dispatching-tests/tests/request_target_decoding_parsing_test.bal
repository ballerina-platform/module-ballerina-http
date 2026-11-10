// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/test;

const int requestTargetParsingTestPort = 9641;

listener http:Listener requestTargetParsingListener = new (requestTargetParsingTestPort, httpVersion = http:HTTP_1_1);
final http:Client requestTargetParsingClient = check new (string `http://localhost:${requestTargetParsingTestPort}`,
    httpVersion = http:HTTP_1_1);

service / on requestTargetParsingListener {
    resource function get albums/[string id]() returns string => "id=[" + id + "]";

    resource function get files/[string... path]() returns string => "path=" + path.toString();

    resource function get nums/[int... ids]() returns string => "ids=" + ids.toString();

    resource function get q(string? x) returns string => "x=[" + (x ?: "()") + "]";

    resource function get bool/[boolean b]() returns string => "b=" + b.toString();

    resource function get boolarr/[boolean... bs]() returns string => "bs=" + bs.toString();

    resource function get qb(boolean flag) returns string => flag.toString();

    resource function get qba(boolean[] flags) returns string => flags.toString();

    resource function get hb(@http:Header boolean x\-flag) returns string => x\-flag.toString();

    resource function get hba(@http:Header boolean[] x\-flags) returns string => x\-flags.toString();
}

service /fb on requestTargetParsingListener {
    @http:ResourceConfig {consumes: ["application/json"]}
    resource function post files2(@http:Payload json j) returns string => "post files2";

    resource function get files2/[string... p]() returns string => "get files2 rest";

    @http:ResourceConfig {consumes: ["application/json"]}
    resource function post files3(@http:Payload json j) returns string => "post files3";

    resource function 'default files3/[string... p]() returns string => "default files3 rest";

    resource function get foo() returns string => "get foo";

    resource function post foo/[string... p]() returns string => "post foo rest";
}

service /fb2 on requestTargetParsingListener {
    resource function get files4() returns string => "get files4";

    @http:ResourceConfig {consumes: ["application/json"]}
    resource function post files4/[string... p](@http:Payload json j) returns string => "post files4 rest";
}

service /optsvc on requestTargetParsingListener {
    resource function get x() returns string => "x";
}

const int requestTargetRootRestTestPort = 9642;

listener http:Listener requestTargetRootRestListener = new (requestTargetRootRestTestPort, httpVersion = http:HTTP_1_1);
final http:Client requestTargetRootRestClient = check new (string `http://localhost:${requestTargetRootRestTestPort}`,
    httpVersion = http:HTTP_1_1);

service / on requestTargetRootRestListener {
    resource function get [string... p]() returns string => "root=" + p.toString();

    resource function get getonly/[string... p]() returns string => "getonly=" + p.toString();
}

function assertRequestTarget(string target, int status, string? body = ()) returns error? {
    http:Response res = check requestTargetParsingClient->get(target);
    test:assertEquals(res.statusCode, status, "Status code mismatched for " + target);
    string payload = check res.getTextPayload();
    if body is string {
        test:assertEquals(payload, body, "Payload mismatched for " + target);
    }
    test:assertFalse(payload.includes("java.") || payload.includes("Exception") || payload.includes("URLDecoder"),
        "Java exception text leaked for " + target + ": " + payload);
}

@test:Config {}
function testPathParamPlusIsNotDecodedToSpace() returns error? {
    check assertRequestTarget("/albums/a+b", 200, "id=[a+b]");
}

@test:Config {}
function testPathParamIsDecodedOnlyOnce() returns error? {
    check assertRequestTarget("/albums/%2520", 200, "id=[%20]");
    check assertRequestTarget("/albums/blue%20train", 200, "id=[blue train]");
    check assertRequestTarget("/albums/%2B", 200, "id=[+]");
}

@test:Config {}
function testRestParamDecodedOnceAndPlusKept() returns error? {
    check assertRequestTarget("/files/a+b/%2520", 200, "path=[\"a+b\",\"%20\"]");
}

@test:Config {}
function testPathParamMalformedEscape() returns error? {
    check assertRequestTarget("/albums/%zz", 400);
    check assertRequestTarget("/albums/%", 400);
    check assertRequestTarget("/albums/a%2", 400);
    check assertRequestTarget("/files/ok/%zz", 400);
}

@test:Config {}
function testQueryValueMalformedEscape() returns error? {
    check assertRequestTarget("/q?x=%zz", 400);
    check assertRequestTarget("/q?x=100%", 400);
    check assertRequestTarget("/q?x=100%25", 200, "x=[100%]");
}

@test:Config {}
function testSecondQuestionMarkStaysInQuery() returns error? {
    check assertRequestTarget("/q?x=1?y=2", 200, "x=[1?y=2]");
}

@test:Config {}
function testRestParamMatchesZeroSegments() returns error? {
    check assertRequestTarget("/files", 200, "path=[]");
    check assertRequestTarget("/files/", 200, "path=[]");
    check assertRequestTarget("/files/x", 200, "path=[\"x\"]");
    check assertRequestTarget("/nums", 200, "ids=[]");
}

@test:Config {}
function testBooleanPathParamStrict() returns error? {
    check assertRequestTarget("/bool/true", 200, "b=true");
    check assertRequestTarget("/bool/TRUE", 200, "b=true");
    check assertRequestTarget("/bool/False", 200, "b=false");
    check assertRequestTarget("/bool/abc", 400);
    check assertRequestTarget("/bool/yes", 400);
    check assertRequestTarget("/boolarr/true/false", 200, "bs=[true,false]");
    check assertRequestTarget("/boolarr/true/abc", 400);
}

@test:Config {}
function testBooleanQueryParamStrict() returns error? {
    check assertRequestTarget("/qb?flag=true", 200, "true");
    check assertRequestTarget("/qb?flag=FALSE", 200, "false");
    check assertRequestTarget("/qb?flag=abc", 400);
    check assertRequestTarget("/qb?flag=yes", 400);
    check assertRequestTarget("/qba?flags=true,false", 200, "[true,false]");
    check assertRequestTarget("/qba?flags=true,abc", 400);
}

@test:Config {}
function testBooleanHeaderParamStrict() returns error? {
    http:Response res = check requestTargetParsingClient->get("/hb", {"x-flag": "TRUE"});
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(check res.getTextPayload(), "true");
    res = check requestTargetParsingClient->get("/hb", {"x-flag": "abc"});
    test:assertEquals(res.statusCode, 400);
    res = check requestTargetParsingClient->get("/hba", {"x-flags": ["true", "abc"]});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testTrailingQuestionMarkStaysInQuery() returns error? {
    check assertRequestTarget("/q?x=1?", 200, "x=[1?]");
    check assertRequestTarget("/q?x=?", 200, "x=[?]");
}

@test:Config {}
function testRootLevelRestParamMatchesRoot() returns error? {
    http:Response res = check requestTargetRootRestClient->get("/");
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(check res.getTextPayload(), "root=[]");
    res = check requestTargetRootRestClient->get("/a/b");
    test:assertEquals(check res.getTextPayload(), "root=[\"a\",\"b\"]");
}

@test:Config {}
function testZeroSegmentRestResourceKeepsMethodSearchRule() returns error? {
    http:Response res = check requestTargetRootRestClient->get("/getonly");
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(check res.getTextPayload(), "getonly=[]");
    http:Response withSegment = check requestTargetRootRestClient->post("/getonly/x", "p");
    http:Response zeroSegments = check requestTargetRootRestClient->post("/getonly", "p");
    test:assertEquals(withSegment.statusCode, 405);
    test:assertEquals(zeroSegments.statusCode, withSegment.statusCode,
        "Zero-segment rest match must report the same status as a one-segment match");
}

@test:Config {}
function testBooleanArrayHeaderPositive() returns error? {
    http:Response res = check requestTargetParsingClient->get("/hba", {"x-flags": ["true", "FALSE"]});
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(check res.getTextPayload(), "[true,false]");
}

@test:Config {}
function testBooleanParsingIsAsciiOnly() returns error? {
    // U+017F (long s) case-folds to 's' in some Unicode comparisons.
    check assertRequestTarget("/bool/fal%C5%BFe", 400);
    check assertRequestTarget("/qb?flag=fal%C5%BFe", 400);
}

@test:Config {}
function testQueryPlusIsSpaceButEncodedPlusIsPlus() returns error? {
    check assertRequestTarget("/q?x=a+b", 200, "x=[a b]");
    check assertRequestTarget("/q?x=a%2Bb", 200, "x=[a+b]");
}

@test:Config {}
function testEncodedSlashInSegments() returns error? {
    check assertRequestTarget("/albums/a%2Fb", 200, "id=[a/b]");
    check assertRequestTarget("/files/a%2Fb/c", 200, "path=[\"a/b\",\"c\"]");
}

@test:Config {}
function testEscapesDecodingToInvalidUtf8AreRejected() returns error? {
    check assertRequestTarget("/albums/%FF", 400);
    check assertRequestTarget("/albums/%C0%AE", 400);
    check assertRequestTarget("/files/ok/%FF", 400);
    check assertRequestTarget("/q?x=%FF", 400);
    check assertRequestTarget("/q?x=%C0%AE", 400);
    check assertRequestTarget("/albums/caf%C3%A9", 200, "id=[café]");
    check assertRequestTarget("/q?x=caf%C3%A9", 200, "x=[café]");
}

@test:Config {}
function testSemicolonOnlySegmentIsClientError()returns error? {
    check assertRequestTarget("/;", 400);
    check assertRequestTarget("/albums/;", 400);
}

@test:Config {}
function testOptionsWithEmptyQueryOnBasePath() returns error? {
    http:Response res = check requestTargetParsingClient->options("/optsvc?");
    test:assertEquals(res.statusCode, 204);
}

@test:Config {}
function testZeroSegmentFallbackDoesNotOverrideRejectedExactResource() returns error? {
    http:Response res = check requestTargetParsingClient->post("/fb/files2", "text", mediaType = "text/plain");
    test:assertEquals(res.statusCode, 415, "unsupported media type must not become 405");
    res = check requestTargetParsingClient->post("/fb/files3", "text", mediaType = "text/plain");
    test:assertEquals(res.statusCode, 415, "must not be dispatched to the default rest resource");
    res = check requestTargetParsingClient->get("/fb/files2");
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(check res.getTextPayload(), "get files2 rest");
}

@test:Config {}
function testZeroSegmentRestChildMediaErrorIsPreserved() returns error? {
    http:Response res = check requestTargetParsingClient->post("/fb2/files4", "text", mediaType = "text/plain");
    test:assertEquals(res.statusCode, 415, "the rest child handles POST but rejects the media type");
    res = check requestTargetParsingClient->post("/fb2/files4", {a: 1});
    test:assertEquals(res.statusCode, 201);
    res = check requestTargetParsingClient->put("/fb2/files4", "x");
    test:assertEquals(res.statusCode, 405, "neither resource handles PUT");
}
