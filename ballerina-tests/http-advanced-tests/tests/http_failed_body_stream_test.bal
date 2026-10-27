// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
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
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/time;

// Returns the given number of blocks, then fails.
class FailingBody {
    private final int blocks;
    private final int blockSize;
    private int count = 0;

    isolated function init(int blocks, int blockSize) {
        self.blocks = blocks;
        self.blockSize = blockSize;
    }

    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        lock {
            self.count += 1;
            if self.count > self.blocks {
                return error io:GenericError("disk failure");
            }
            return {value: "".padEnd(self.blockSize, "x").toBytes()};
        }
    }
}

isolated string[] failedUploadOutcomes = [];

listener http:Listener failedBodyHttp2Listener = new (failedBodyHttp2TestPort);
listener http:Listener failedBodyHttp1Listener = new (failedBodyHttp1TestPort, httpVersion = http:HTTP_1_1);

service /failedBody on failedBodyHttp2Listener, failedBodyHttp1Listener {
    // Fails before the first 8 KB buffer fills, so nothing has been sent yet.
    resource function get early() returns http:Response => newFailingResponse(1, 7);

    // Fails after the headers and some of the body have been sent.
    resource function get late() returns http:Response => newFailingResponse(3, 10000);

    resource function get ok() returns string => "ok";

    resource function post upload(http:Request request) returns string {
        byte[]|error body = request.getBinaryPayload();
        string outcome = body is error ? "failed" : string `received ${body.length()} bytes`;
        lock {
            failedUploadOutcomes.push(outcome);
        }
        return outcome;
    }
}

@http:ServiceConfig {chunking: http:CHUNKING_NEVER}
service /failedBodyUnchunked on failedBodyHttp2Listener, failedBodyHttp1Listener {
    resource function get early() returns http:Response => newFailingResponse(1, 7);

    resource function get late() returns http:Response => newFailingResponse(3, 10000);
}

final http:Client failedBodyHttp2Backend = check new (string `http://localhost:${failedBodyHttp2TestPort}`,
    http2Settings = {http2PriorKnowledge: true});
final http:Client failedBodyHttp1Backend = check new (string `http://localhost:${failedBodyHttp1TestPort}`,
    httpVersion = http:HTTP_1_1);

// A backend response that fails before its headers is an error at the proxy, so only a later failure passes through.
service /failedBodyProxy on failedBodyHttp2Listener {
    resource function get late() returns http:Response|error {
        return failedBodyHttp2Backend->get("/failedBody/late");
    }
}

service /failedBodyProxy on failedBodyHttp1Listener {
    resource function get late() returns http:Response|error {
        return failedBodyHttp1Backend->get("/failedBody/late");
    }
}

isolated function newFailingResponse(int blocks, int blockSize) returns http:Response {
    http:Response response = new;
    response.setHeader("x-failing-body", "true");
    response.setByteStream(new stream<byte[], io:Error?>(new FailingBody(blocks, blockSize)));
    return response;
}

// Nothing has been sent when the body fails, as a chunking: NEVER HTTP/1.1 response holds back its whole body.
isolated function failsBeforeSending(string path, http:HttpVersion httpVersion) returns boolean =>
    path.endsWith("/early") || (path == "failedBodyUnchunked/late" && httpVersion == http:HTTP_1_1);

final readonly & [int, http:HttpVersion][] failedBodyTargets =
    [[failedBodyHttp2TestPort, http:HTTP_2_0], [failedBodyHttp1TestPort, http:HTTP_1_1]];

@test:Config {}
function testResponseWhoseByteStreamFailsIsFailedAtTheClient() returns error? {
    foreach [int, http:HttpVersion] [port, httpVersion] in failedBodyTargets {
        // One client, so a connection that wrongly outlives an aborted response fails the next request on it
        http:Client failedBodyClient = check new (string `http://localhost:${port}`, httpVersion = httpVersion,
            timeout = 10);
        foreach string path in ["failedBody/early", "failedBody/late", "failedBodyUnchunked/early",
                "failedBodyUnchunked/late", "failedBodyProxy/late"] {
            decimal startTime = time:monotonicNow();
            http:Response|error response = failedBodyClient->get("/" + path);
            decimal elapsed = time:monotonicNow() - startTime;
            string target = string `${httpVersion} /${path}`;
            if failsBeforeSending(path, httpVersion) {
                test:assertTrue(response is http:Response && response.statusCode == 500 &&
                    !response.hasHeader("x-failing-body"), string `${target}: expected a bare 500`);
            } else {
                byte[]|error body = response is error ? response : response.getBinaryPayload();
                test:assertTrue(body is error, string `${target}: the failed body was received as complete`);
            }
            test:assertTrue(elapsed < 5d, string `${target}: the failure took ${elapsed}s to reach the client`);

            string|error next = failedBodyClient->get("/failedBody/ok");
            test:assertEquals(next, "ok", string `${target}: the next request on the client failed`);
        }
    }
}

@test:Config {}
function testRequestWhoseByteStreamFailsIsAborted() returns error? {
    foreach [int, http:HttpVersion] [port, httpVersion] in failedBodyTargets {
        lock {
            failedUploadOutcomes.removeAll();
        }
        // Prior knowledge, as an upgrade request is only handed to the service once its whole body has arrived
        http:Client failedBodyClient = check new (string `http://localhost:${port}`, httpVersion = httpVersion,
            http2Settings = {http2PriorKnowledge: true}, timeout = 10);
        http:Request request = new;
        request.setByteStream(new stream<byte[], io:Error?>(new FailingBody(3, 10000)));
        string|error result = failedBodyClient->post("/failedBody/upload", request);
        test:assertTrue(result is error, string `${httpVersion}: the failed request body was sent as complete`);

        string[] outcomes = [];
        foreach int _ in 0 ..< 50 {
            lock {
                outcomes = failedUploadOutcomes.clone();
            }
            if outcomes.length() > 0 {
                break;
            }
            runtime:sleep(0.1);
        }
        test:assertEquals(outcomes, ["failed"], string `${httpVersion}: the service did not see the body fail`);
    }
}
