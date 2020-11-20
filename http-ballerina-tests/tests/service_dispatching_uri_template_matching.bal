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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/lang.'float as langfloat;
import ballerina/lang.'int as langint;
import ballerina/stringutils;
import ballerina/test;
import ballerina/http;

listener http:Listener utmTestEP = new(uriTemplateMatchingTest);
http:Client utmClient = new("http://localhost:" + uriTemplateMatchingTest.toString());

@http:ServiceConfig {
    basePath:"/hello"
}
service echo11 on utmTestEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"echo2"
    }
    resource function echo1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo5":"echo5"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/{abc}"
    }
    resource function echo4(http:Caller caller, http:Request req, string abc) {
        http:Response res = new;
        json responseJson = {"echo3":abc};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/{abc}/bar"
    }
    resource function echo5(http:Caller caller, http:Request req, string abc) {
        http:Response res = new;
        json responseJson = {"first":abc, "echo4":"echo4"};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/{xyz}.id"
    }
    resource function echo6(http:Caller caller, http:Request req, string xyz) {
        http:Response res = new;
        json responseJson = {"echo6":xyz};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/literal.id"
    }
    resource function echo6_1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo6":"literal invoked"};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/{zz}.id/foo"
    }
    resource function echo6_2(http:Caller caller, http:Request req, string zz) {
        http:Response res = new;
        json responseJson = {"echo6":"specific path invoked"};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/{xyz}.identity"
    }
    resource function echo6_3(http:Caller caller, http:Request req, string xyz) {
        http:Response res = new;
        json responseJson = {"echo6":"identity"};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/*"
    }
    resource function echo7(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo5":"any"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo3/{abc}"
    }
    resource function echo9(http:Caller caller, http:Request req, string abc) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"first":abc, "second":(foo is string[] ? foo[0] : "go"), "echo9":"echo9"};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function echo10(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third":(foo is string[] ? foo[0] : "go"), "echo10":"echo10"};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function echo11(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third":(foo is string[] ? foo[0] : ""), "echo11":"echo11"};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo12/{abc}/bar"
    }
    resource function echo12(http:Caller caller, http:Request req, string abc) {
        http:Response res = new;
        json responseJson = {"echo12":abc};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo125"
    }
    resource function echo125(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? bar = params["foo"];
        json responseJson = {"echo125":(bar is string[] ? bar[0] : "")};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/paramNeg"
    }
    resource function paramNeg(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? bar = params["foo"] ?: [""];
        json responseJson = {"echo125":(bar is string[] ? bar[0] : "")};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo13"
    }
    resource function echo13(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        var result = langint:fromString(barStr is string[] ? barStr[0] : "0");
        int bar = (result is int) ? result : 0;
        json responseJson = {"echo13":bar};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo14"
    }
    resource function echo14(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        var result = langfloat:fromString(barStr is string[] ? barStr[0] : "0.0");
        float bar = (result is float) ? result : 0.0;
        json responseJson = {"echo14":bar};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo15"
    }
    resource function echo15(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        string val = barStr is string[] ? barStr[0] : "";
        boolean bar = stringutils:toBoolean(val);
        json responseJson = {"echo15":bar};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo155"
    }
    resource function sameName(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        string[]? bar = params["bar"];
        string name1 = foo is string[] ? foo[0] : "";
        string name2 = foo is string[] ? foo[1] : "";
        string name3 = bar is string[] ? bar[0] : "";
        string name4 = foo is string[] ? foo[2] : "";
        json responseJson = {"name1":name1 , "name2":name2, "name3":(name3 != "" ? name3 : ()),
                                "name4":name4};
        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo156/{key}"
    }
    resource function allApis(http:Caller caller, http:Request req, string key) {
        map<string[]> paramMap = req.getQueryParams();
        string[] valueArray = req.getQueryParamValues(<@untainted> key) ?: ["array not found"];
        string value = req.getQueryParamValue(<@untainted> key) ?: "value not found";
        string[]? paramVals = paramMap[key];
        string mapVal = paramVals is string[] ? paramVals[0] : "";
        string[]? paramVals2 = paramMap["foo"];
        string mapVal2 = paramVals2 is string[] ? paramVals2[0] : "";
        json responseJson = {"map":mapVal , "array":valueArray[0], "value":value,
                                "map_":mapVal2, "array_":valueArray[1] };
        //http:Response res = new;
        //res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(<@untainted> responseJson);
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/so2"
    }
    resource function echo(http:Caller caller, http:Request req) {
    }
}

@http:ServiceConfig {
    basePath:"/hello/world"
}
service echo22 on utmTestEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2"
    }
    resource function echo1(http:Caller caller, http:Request req) {
        json responseJson = {"echo1":"echo1"};
        http:Response res = new;
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/*"
    }
    resource function echo2(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo2":"echo2"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo2/foo/bar"
    }
    resource function echo3(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo3":"echo3"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/"
}
service echo33 on utmTestEP {
    resource function echo1(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third":(foo is string[] ? foo[0] : ""), "echo33":"echo1"};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }
}

service echo44 on utmTestEP {

    @http:ResourceConfig {
        path:"echo2"
    }
    resource function echo221(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"first":"zzz"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function echo1(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"first":(foo is string[] ? foo[0] : ""), "echo44":"echo1"};

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"echo2"
    }
    resource function echo222(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"first":"bar"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service echo55 on utmTestEP {
    @http:ResourceConfig {
        path:"/foo/bar"
    }
    resource function echo1(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"echo55":"echo55"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/*"
    }
    resource function echo2(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo55":"default"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/foo/*"
    }
    resource function echo5(http:Caller caller, http:Request req) {
        map<string[]> params = req.getQueryParams();
        string[] foo = params["foo"] ?: [];
        json responseJson = {"echo55":"/foo/*"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service echo69 on utmTestEP {
    @http:ResourceConfig {
        path:"/a/*"
    }
    resource function echo1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo66":req.extraPathInfo};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/a"
    }
    resource function echo2(http:Caller caller, http:Request req) {
        http:Response res = new;
        if (req.extraPathInfo == "") {
            req.extraPathInfo = "empty";
        }
        json responseJson = {"echo66":req.extraPathInfo};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/uri"
}
service WildcardService on utmTestEP {

    @http:ResourceConfig {
        path:"/{id}",
        methods:["POST"]
    }
    resource function pathParamResource(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {message:"Path Params Resource is invoked."};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/*"
    }
    resource function wildcardResource(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {message:"Wildcard Params Resource is invoked."};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/go/{aaa}/{bbb}/{ccc}"
    }
    resource function threePathParams(http:Caller caller, http:Request req, string aaa, string bbb, string ccc) {
        http:Response res = new;
        json responseJson = {aaa:aaa, bbb:bbb, ccc:ccc};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/go/{xxx}/{yyy}"
    }
    resource function twoPathParams(http:Caller caller, http:Request req, string xxx, string yyy) {
        http:Response res = new;
        json responseJson = {xxx:xxx, yyy:yyy};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/Go"
    }
    resource function CapitalizedPathParams(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {value:"capitalized"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/twisted/{age}/{name}"
    }
    resource function twistedPathParams(http:Caller caller, http:Request req, string name, string age) {
        http:Response res = new;
        json responseJson = { Name:name, Age:age };
        checkpanic caller->respond(<@untainted> responseJson);
    }

    @http:ResourceConfig {
        path:"/type/{age}/{name}/{status}/{weight}"
    }
    resource function MultiTypedPathParams(http:Caller caller, http:Request req, string name, int age,
                                            float weight, boolean status) {
        http:Response res = new;
        int balAge = age + 1;
        float balWeight = weight + 2.95;
        string balName = name + " false";
        if (status) {
            balName = name;
        }
        json responseJson = { Name:name, Age:balAge, Weight:balWeight, Status:status, Lang: balName};
        checkpanic caller->respond(<@untainted> responseJson);
    }
}

@http:ServiceConfig {
    basePath:"/encodedUri"
}
service URLEncodeService on utmTestEP {
    @http:ResourceConfig {
        path:"/test/{aaa}/{bbb}/{ccc}"
    }
    resource function encodedPath(http:Caller caller, http:Request req, string aaa, string bbb, string ccc) {
        http:Response res = new;
        json responseJson = {aaa:aaa, bbb:bbb, ccc:ccc};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }
}

//Test dispatching with URL. /hello/world/echo2?regid=abc
@test:Config {}
function testMostSpecificMatchWithQueryParam() {
    var response = utmClient->get("/hello/world/echo2?regid=abc");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo1", "echo1");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/world/echo2/bar
@test:Config {}
function testMostSpecificMatchWithWildCard() {
    var response = utmClient->get("/hello/world/echo2/bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo2", "echo2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/world/echo2/foo/bar
@test:Config {}
function testMostSpecificMatch() {
    var response = utmClient->get("/hello/world/echo2/foo/bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo3", "echo3");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2?regid=abc
@test:Config {}
function testMostSpecificServiceDispatch() {
    var response = utmClient->get("/hello/echo2?regid=abc");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo5", "echo5");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSubPathEndsWithPathParam() {
    var response = utmClient->get("/hello/echo2/shafreen");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo3", "shafreen");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen-anfar & /hello/echo2/shafreen+anfar
@test:Config {}
function testMostSpecificWithPathParam() {
    var response = utmClient->get("/hello/echo2/shafreen-anfar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo3", "shafreen-anfar");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo2/shafreen+anfar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo3", "shafreen anfar");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen+anfar/bar
@test:Config {}
function testSubPathEndsWithBar() {
    var response = utmClient->get("/hello/echo2/shafreen+anfar/bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "shafreen anfar");
        assertJsonValue(response.getJsonPayload(), "echo4", "echo4");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen+anfar/foo/bar
@test:Config {}
function testLeastSpecificURITemplate() {
    var response = utmClient->get("/hello/echo2/shafreen+anfar/foo/bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo5", "any");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testParamDefaultValues() {
    var response = utmClient->get("/hello/echo3/shafreen+anfar?foo=bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "shafreen anfar");
        assertJsonValue(response.getJsonPayload(), "second", "bar");
        assertJsonValue(response.getJsonPayload(), "echo9", "echo9");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathParamWithSuffix() {
    var response = utmClient->get("/hello/echo2/suffix.id");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo6", "suffix");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWhenPathLiteralHasSameSuffix() {
    var response = utmClient->get("/hello/echo2/literal.id");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo6", "literal invoked");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSpecificMatchForPathParamWithSuffix() {
    var response = utmClient->get("/hello/echo2/ballerina.id/foo");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo6", "specific path invoked");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathParamWithInvalidSuffix() {
    var response = utmClient->get("/hello/echo2/suffix.hello");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo3", "suffix.hello");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathSegmentContainsBothLeadingDotsAndSuffix() {
    var response = utmClient->get("/hello/echo2/Rs.654.58.id");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo6", "Rs.654.58");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSpecificPathParamSuffix() {
    var response = utmClient->get("/hello/echo2/hello.identity");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo6", "identity");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRootPathDefaultValues() {
    var response = utmClient->get("/hello?foo=zzz");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "third", "zzz");
        assertJsonValue(response.getJsonPayload(), "echo10", "echo10");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDefaultPathDefaultValues() {
    var response = utmClient->get("/hello/echo11?foo=zzz");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "third", "zzz");
        assertJsonValue(response.getJsonPayload(), "echo11", "echo11");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceRoot() {
    var response = utmClient->get("/echo1?foo=zzz");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "third", "zzz");
        assertJsonValue(response.getJsonPayload(), "echo33", "echo1");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllDefaultValues() {
    var response = utmClient->get("/echo44/echo1?foo=zzz");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "zzz");
        assertJsonValue(response.getJsonPayload(), "echo44", "echo1");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWrongGETMethod() {
    var response = utmClient->get("/hello/so2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWrongPOSTMethod() {
    var response = utmClient->post("/hello/echo2", "hi");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testValueWithNextSegmentStartCharacter() {
    var response = utmClient->get("/hello/echo12/bar/bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo12", "bar");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStringQueryParam() {
    var response = utmClient->get("/hello/echo125?foo=hello");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "hello");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamNegative() {
    var response = utmClient->get("/hello/paramNeg");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIntegerQueryParam() {
    var response = utmClient->get("/hello/echo13?foo=1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo13", 1);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo13?foo=");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo13", 0);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testFloatQueryParam() {
    var response = utmClient->get("/hello/echo14?foo=1.11");
    if (response is http:Response) {
        decimal dValue = 1.11;
        assertJsonValue(response.getJsonPayload(), "echo14", dValue);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo14?foo=");
    if (response is http:Response) {
        decimal dValue = 0.0;
        assertJsonValue(response.getJsonPayload(), "echo14", dValue);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBooleanQueryParam() {
    var response = utmClient->get("/hello/echo15?foo=true");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo15", true);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo15?foo=");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo15", false);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSameNameQueryParam() {
    var response = utmClient->get("/hello/echo155?foo=a,b&bar=c&foo=d");
    if (response is http:Response) {
        json expected = {name1:"a", name2:"b", name3:"c", name4:"d"};
        assertJsonPayload(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo155?foo=a,b,c");
    if (response is http:Response) {
        json expected = {name1:"a", name2:"b", name3:null, name4:"d"};
        assertJsonValue(response.getJsonPayload(), "name3", ());
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testQueryParamWithSpecialChars() {
    var response = utmClient->get("/hello/echo125?foo=%25aaa");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "%aaa");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=abc%21");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "abc!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=Owner%20IN%20%28%27owner1%27%2C%27owner2%27%29,Owner%20OUT");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "Owner IN ('owner1','owner2')");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamValueNegative() {
    var response = utmClient->get("/hello?bar=");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "third", "go");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamValuesNegative() {
    var response = utmClient->get("/hello/paramNeg?bar=xxx,zzz");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllInOneQueryParamAPIs() {
    var response = utmClient->get("/hello/echo156/bar?foo=a,b&bar=c&bar=d");
    if (response is http:Response) {
        json expected = {'map:"c", array:"c", value:"c", map_:"a", array_:"d"};
        assertJsonPayload(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo156/zzz?zzz=x,X&bar=x&foo=");
    if (response is http:Response) {
        json expected = {'map:"x", array:"x", value:"x", map_:"", array_:"X"};
        assertJsonPayload(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourceWithoutMethod() {
    var response = utmClient->post("/echo44/echo2", "hi");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->head("/echo44/echo2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->put("/echo44/echo2", "hi");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->delete("/echo44/echo2");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->options("/echo44/echo2");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchingResource() {
    var response = utmClient->get("/echo44/echo2");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "first", "bar");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDefaultResourceSupport() {
    var response = utmClient->post("/echo55/hello", "Test");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo/");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo/abc");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo55", "/foo/*");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRestUriPostFix() {
    var response = utmClient->get("/echo69/a/b/c");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo66", "/b/c");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo69/a/c");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo66", "/c");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo69/a");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo66", "empty");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMatchWithWildCard() {
    var response = utmClient->get("/uri/123");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "message", "Wildcard Params Resource is invoked.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWithWildCard() {
    var response = utmClient->post("/uri/123", "hi");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "message", "Path Params Resource is invoked.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDifferentLengthPathParams() {
    var response = utmClient->get("/uri/go/wso2/ballerina/http");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "aaa", "wso2");
        assertJsonValue(response.getJsonPayload(), "bbb", "ballerina");
        assertJsonValue(response.getJsonPayload(), "ccc", "http");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/uri/go/123/456");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "xxx", "123");
        assertJsonValue(response.getJsonPayload(), "yyy", "456");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWithCapitalizedPathSegments() {
    var response = utmClient->post("/uri/Go", "POST");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "value", "capitalized");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testTwistedPathSegmentsInTheSignature() {
    var response = utmClient->get("/uri/twisted/20/john");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Name", "john");
        assertJsonValue(response.getJsonPayload(), "Age", "20");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultiTypePathSegmentsInTheSignature() {
    var response = utmClient->get("/uri/type/20/ballerina/true/15.6");
    if (response is http:Response) {
        decimal dValue = 18.55;
        assertJsonValue(response.getJsonPayload(), "Name", "ballerina");
        assertJsonValue(response.getJsonPayload(), "Age", 21);
        assertJsonValue(response.getJsonPayload(), "Weight", dValue);
        assertJsonValue(response.getJsonPayload(), "Status", true);
        assertJsonValue(response.getJsonPayload(), "Lang", "ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/uri/type/120/hello/false/15.9");
    if (response is http:Response) {
        decimal dValue = 18.85;
        assertJsonValue(response.getJsonPayload(), "Name", "hello");
        assertJsonValue(response.getJsonPayload(), "Age", 121);
        assertJsonValue(response.getJsonPayload(), "Weight", dValue);
        assertJsonValue(response.getJsonPayload(), "Status", false);
        assertJsonValue(response.getJsonPayload(), "Lang", "hello false");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEncodedPathParams() {
    var response = utmClient->get("/uri/go/1%2F1/ballerina/1%2F3");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "aaa", "1/1");
        assertJsonValue(response.getJsonPayload(), "bbb", "ballerina");
        assertJsonValue(response.getJsonPayload(), "ccc", "1/3");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/uri/go/123/456");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "xxx", "123");
        assertJsonValue(response.getJsonPayload(), "yyy", "456");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
