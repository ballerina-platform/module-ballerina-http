// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/url;
import ballerina/http_test_common as common;

final http:Client clientResourceMethodsClientEP = check new ("http://localhost:" + clientResourceMethodsTestPort.toString());

final http:FailoverClient failoverClientEP = check new (
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    targets = [
    {url: "http://localhost:" + clientResourceMethodsTestPort.toString()}
]
);

final http:LoadBalanceClient loadBalancerClientEP = check new (
    targets = [
    {url: "http://localhost:" + clientResourceMethodsTestPort.toString()}
],
    timeout = 5
);

listener http:Listener clientResourceMethodsServerEP = check new (clientResourceMethodsTestPort);

service /foo on clientResourceMethodsServerEP {

    resource function get [string path](@http:Header string? x\-name, int? id) returns string {
        if x\-name is string {
            return "Greetings! from GET " + path + " to " + x\-name;
        }
        if id is int {
            return "Greetings! from GET " + path + " to user id : " + id.toString();
        }
        return "Greetings! from GET " + path;
    }

    resource function post [string path](http:Request req, string? name) returns string|error {
        string contentType = req.getContentType();
        string greeting = check req.getTextPayload();
        if contentType == mime:APPLICATION_FORM_URLENCODED {
            string decodedContent = check url:decode(greeting, "UTF-8");
            return decodedContent;
        }
        if name is string {
            return greeting + " from POST " + path + " to " + name;
        }
        return greeting + " from POST " + path;
    }

    resource function post person(@http:Payload Person person, @http:Header string? x\-header, int id) returns string {
        string greeting = x\-header ?: "Greetings!";
        return greeting + " from POST person to " + person.name + " with id : " + id.toString();
    }

    resource function put [string path](http:Request req, string[]? names) returns string|error {
        string greeting = check req.getTextPayload();
        if names is () {
            return greeting + " from PUT " + path;
        } else {
            string[] msg = [];
            foreach string name in names {
                msg.push(greeting + " from PUT " + path + " to " + name);
            }
            return strings:'join(", ", ...msg);
        }
    }

    resource function delete [string path](@http:Header string[] x\-names, @http:Payload string? payload) returns string {
        string greeting = payload ?: "Hi";
        string[] msg = [];
        foreach string name in x\-names {
            msg.push(greeting + " from DELETE " + path + " to " + name);
        }
        return strings:'join(", ", ...msg);
    }

    resource function patch [string path](@http:Payload string greeting, string name, int id) returns string {
        return greeting + " from PATCH " + path + " to " + name + " with user id : " + id.toString();
    }

    resource function head [string path](@http:Header string x\-greeting, string name) returns string {
        return x\-greeting + " from HEAD " + path + " to " + name;
    }

    resource function options [string path](@http:Header string x\-greeting, string name) returns string {
        return x\-greeting + " from OPTIONS " + path + " to " + name;
    }
}

service on clientResourceMethodsServerEP {

    resource function 'default [string... path]() returns string {
        return "Greetings! from path /" + strings:'join("/", ...path);
    }

    resource function get bar/[string str]/[int i]/[float f]/[decimal d]/[boolean b]() returns json {
        return {
            msg: "Greetings! from mixed path params",
            path: "/bar/" + strings:'join("/", str, i.toString(), f.toString(), d.toString(), b.toString())
        };
    }
}

service /query on clientResourceMethodsServerEP {

    resource function get bar(string first\-name, string 'table, int age) returns string {
        return string `Greetings! from query params: ${first\-name}, ${'table}, ${age.toString()}`;
    }

    resource function get bar/[int pathParam](string first\-name, string 'table, int age) returns string {
        return string `Greetings! from query with path param, query: ${first\-name}, path: ${pathParam}`;
    }

    resource function post bar/[int pathParam](Person body, string first\-name, string 'table, int age) returns string {
        return string `Greetings! from query with path param and request payload, query: ${first\-name}, payload.name: ${body.name}, path: ${pathParam}`;
    }

    resource function put bar/[int pathParam](Person body, string first\-name, int age) returns string {
        return string `Greetings! from query with different annotation, query: ${first\-name}`;
    }
}

@test:Config {}
function testClientGetResource() returns error? {
    string response = check clientResourceMethodsClientEP->/foo/bar();
    test:assertEquals(response, "Greetings! from GET bar");
    response = check clientResourceMethodsClientEP->/foo/baz.get();
    test:assertEquals(response, "Greetings! from GET baz");

    string[] paths = ["foo", "baz"];
    response = check clientResourceMethodsClientEP->/[paths[0]]/bar({"x-name": "James"});
    test:assertEquals(response, "Greetings! from GET bar to James");
    response = check clientResourceMethodsClientEP->/[...paths](id = 1234);
    test:assertEquals(response, "Greetings! from GET baz to user id : 1234");

    response = check clientResourceMethodsClientEP->/foo/bar(id = 1234, headers = {"x-name": "James"});
    test:assertEquals(response, "Greetings! from GET bar to James");

    var resp = check clientResourceMethodsClientEP->/foo/bar(targetType = string, id = 1234);
    test:assertEquals(resp, "Greetings! from GET bar to user id : 1234");
    resp = check clientResourceMethodsClientEP->/foo/bar({"x-name": "James"}, string, id = 1234);
    test:assertEquals(resp, "Greetings! from GET bar to James");
}

@test:Config {}
function testClientPostResource() returns error? {
    string response = check clientResourceMethodsClientEP->/foo/bar.post("Hello");
    test:assertEquals(response, "Hello from POST bar");
    response = check clientResourceMethodsClientEP->/foo/baz.post("Hello", name = "James");
    test:assertEquals(response, "Hello from POST baz to James");
    response = check clientResourceMethodsClientEP->/foo/bar.post(name = "John", message = "Hi");
    test:assertEquals(response, "Hi from POST bar to John");

    Person person = {name: "Henry", age: 35};
    response = check clientResourceMethodsClientEP->/foo/person.post(person, id = 1234);
    test:assertEquals(response, "Greetings! from POST person to Henry with id : 1234");
    response = check clientResourceMethodsClientEP->/foo/person.post(person, {x\-header: "Hello"}, id = 1234);
    test:assertEquals(response, "Hello from POST person to Henry with id : 1234");
    response = check clientResourceMethodsClientEP->/foo/bar.post(payload, mediaType = mime:APPLICATION_FORM_URLENCODED);
    test:assertEquals(response, "key1=value1&key2=value2");
}

@test:Config {}
function testClientPutResource() returns error? {
    http:Request req = new;
    req.setTextPayload("Howdy!");
    string response = check clientResourceMethodsClientEP->/foo/baz.put(req);
    test:assertEquals(response, "Howdy! from PUT baz");
    response = check clientResourceMethodsClientEP->/foo/baz.put("Hello", names = ["John", "James", "Howard"]);
    test:assertEquals(response, "Hello from PUT baz to John, Hello from PUT baz to James, Hello from PUT baz to Howard");
    response = check clientResourceMethodsClientEP->/foo/baz.put(names = ["John", 4, true, 5.64], message = "Hello");
    test:assertEquals(response, "Hello from PUT baz to John, Hello from PUT baz to 4, Hello from PUT baz to true, " +
                                "Hello from PUT baz to 5.64");
}

@test:Config {}
function testClientDeleteResource() returns error? {
    string response = check clientResourceMethodsClientEP->/foo/bar.delete(headers = {x\-names: ["John", "James"]});
    test:assertEquals(response, "Hi from DELETE bar to John, Hi from DELETE bar to James");
    response = check clientResourceMethodsClientEP->/foo/bar.delete("Hello", {x\-names: ["John", "James"]});
    test:assertEquals(response, "Hello from DELETE bar to John, Hello from DELETE bar to James");
}

@test:Config {}
function testClientPatchResource() returns error? {
    string response = check clientResourceMethodsClientEP->/foo/bar.patch("Hello", name = "John", id = 1234);
    test:assertEquals(response, "Hello from PATCH bar to John with user id : 1234");
    response = check clientResourceMethodsClientEP->/foo/bar.patch("Hi", params = {"id": 4321, "name": "James"});
    test:assertEquals(response, "Hi from PATCH bar to James with user id : 4321");
}

@test:Config {}
function testClientHeadResource() returns error? {
    http:Response response = check clientResourceMethodsClientEP->/foo/barBaz.head({x\-greeting: "Hey"}, {"name": "George"});
    common:assertTextPayload(response.getTextPayload(), "Hey from HEAD barBaz to George");
}

@test:Config {}
function testClientOptionsResource() returns error? {
    string response = check clientResourceMethodsClientEP->/foo/bar.options(name = "John", headers = {x\-greeting: "Hey"});
    test:assertEquals(response, "Hey from OPTIONS bar to John");
}

@test:Config {}
function testResourceMethodsInFailoverClient() returns error? {
    check testResourceMethodsWithOtherPublicClients(failoverClientEP);
}

@test:Config {}
function testResourceMethodsInLoadBalancerClient() returns error? {
    check testResourceMethodsWithOtherPublicClients(loadBalancerClientEP);
}

function testResourceMethodsWithOtherPublicClients(http:ClientObject clientEP) returns error? {
    string response = check clientEP->/foo/bar.post("Hello");
    test:assertEquals(response, "Hello from POST bar");
    response = check clientEP->/foo/bar.put("Hello");
    test:assertEquals(response, "Hello from PUT bar");
    response = check clientEP->/foo/bar.patch("Hi", params = {"id": 4321, "name": "James"});
    test:assertEquals(response, "Hi from PATCH bar to James with user id : 4321");
    response = check clientEP->/foo/bar.delete("Hello", {x\-names: ["John", "James"]});
    test:assertEquals(response, "Hello from DELETE bar to John, Hello from DELETE bar to James");
    response = check clientEP->/foo/bar();
    test:assertEquals(response, "Greetings! from GET bar");
    response = check clientEP->/foo/bar.options({x\-greeting: "Hey"}, name = "John");
    test:assertEquals(response, "Hey from OPTIONS bar to John");
    http:Response resp = check clientEP->/foo/barBaz.head({x\-greeting: "Hey"}, {"name": "George"});
    common:assertTextPayload(resp.getTextPayload(), "Hey from HEAD barBaz to George");
}

@test:Config {}
function testClientResourceWithBasicType() returns error? {
    string response = check clientResourceMethodsClientEP->/baz/[45.78]/foo;
    test:assertEquals(response, "Greetings! from path /baz/45.78/foo");

    response = check clientResourceMethodsClientEP->/baz/'45\.78/foo.post("Hello!");
    test:assertEquals(response, "Greetings! from path /baz/45.78/foo");

    map<json> res = check clientResourceMethodsClientEP->/bar/'false/[45]/[34.5]/[45.6d]/[false];
    test:assertEquals(res["msg"], "Greetings! from mixed path params");
    test:assertEquals(res["path"], "/bar/false/45/34.5/45.6/false");

    string|int id = "2453D";
    response = check clientResourceMethodsClientEP->/baz/[id];
    test:assertEquals(response, "Greetings! from path /baz/2453D");

    id = 2453;
    response = check clientResourceMethodsClientEP->/baz/[id];
    test:assertEquals(response, "Greetings! from path /baz/2453");
}

@test:Config {}
function testClientResourceWithBasicRestType() returns error? {
    string[] path0 = [];
    string response = check clientResourceMethodsClientEP->/[...path0];
    test:assertEquals(response, "Greetings! from path /");

    string[] paths1 = ["baz", "45", "true", "34.5", "45.6d"];
    response = check clientResourceMethodsClientEP->/[...paths1];
    test:assertEquals(response, "Greetings! from path /baz/45/true/34.5/45.6d");

    int[] paths2 = [1, 2, 3, 4, 5];
    response = check clientResourceMethodsClientEP->/[...paths2].post("Hello!");
    test:assertEquals(response, "Greetings! from path /1/2/3/4/5");

    float[] paths3 = [1.1, 2.2, 3.3, 4.4, 5.5];
    response = check clientResourceMethodsClientEP->/[...paths3];
    test:assertEquals(response, "Greetings! from path /1.1/2.2/3.3/4.4/5.5");

    boolean[] paths4 = [true, false, true, false, true];
    response = check clientResourceMethodsClientEP->/[...paths4].delete();
    test:assertEquals(response, "Greetings! from path /true/false/true/false/true");

    decimal[] paths5 = [1.1d, 2.2d, 3.3d, 4.4d, 5.5d];
    response = check clientResourceMethodsClientEP->/[...paths5];
    test:assertEquals(response, "Greetings! from path /1.1/2.2/3.3/4.4/5.5");

    (string|int|float|decimal|boolean)[] paths6 = ["bar", "foo", 45, 34.5, 45.6d, true];
    map<json> res = check clientResourceMethodsClientEP->/[...paths6];
    test:assertEquals(res["msg"], "Greetings! from mixed path params");
    test:assertEquals(res["path"], "/bar/foo/45/34.5/45.6/true");
}

public type QueryParams record {|
    @http:Query {name: "first-name"}
    string first\-Name;
    @http:Query {name: "table"}
    string tableNo;
    @http:Query {name: "age"}
    int personAge;
|};


public type MetaInfo record {|
    string name;
|};
public const annotation MetaInfo Meta on record field;
public type QueryWithDifferentAnnotation record {|
    @http:Query {name: "first-name"}
    @Meta {
        name: "Potter"
    }
    string firstName;
    int age;
|};

@test:Config {}
function testQueryParametersNameOverride() returns error? {
    QueryParams queries = {
        first\-Name: "Jhon",
        tableNo: "10",
        personAge: 29
    };

    string response = check clientResourceMethodsClientEP->/query/bar.get(params = queries);
    test:assertEquals(response, "Greetings! from query params: Jhon, 10, 29");

    response = check clientResourceMethodsClientEP->/query/bar/[99].get(params = queries);
    test:assertEquals(response, "Greetings! from query with path param, query: Jhon, path: 99");

    Person person = {
        name: "Harry",
        age: 29
    };

    response = check clientResourceMethodsClientEP->/query/bar/[99].post(person, params = queries);
    test:assertEquals(response, "Greetings! from query with path param and request payload, query: Jhon, payload.name: Harry, path: 99");

    QueryWithDifferentAnnotation annotQ = {
        firstName: "Ron",
        age: 29
    };
    response = check clientResourceMethodsClientEP->/query/bar/[99].put(person, params = annotQ);
    test:assertEquals(response, "Greetings! from query with different annotation, query: Ron");
}
