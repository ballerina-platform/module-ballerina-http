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
    resource function get early() returns http:Response {
        http:Response response = new;
        response.setByteStream(new stream<byte[], io:Error?>(new FailingBody(1, 7)));
        return response;
    }

    // Fails after the headers and some of the body have been sent.
    resource function get late() returns http:Response {
        http:Response response = new;
        response.setByteStream(new stream<byte[], io:Error?>(new FailingBody(3, 10000)));
        return response;
    }

    resource function post upload(http:Request request) returns string {
        byte[]|error body = request.getBinaryPayload();
        string outcome = body is error ? "failed" : string `received ${body.length()} bytes`;
        lock {
            failedUploadOutcomes.push(outcome);
        }
        return outcome;
    }
}

final readonly & [int, http:HttpVersion][] failedBodyTargets =
    [[failedBodyHttp2TestPort, http:HTTP_2_0], [failedBodyHttp1TestPort, http:HTTP_1_1]];

@test:Config {}
function testResponseWhoseByteStreamFailsIsAborted() returns error? {
    foreach [int, http:HttpVersion] [port, httpVersion] in failedBodyTargets {
        foreach string path in ["early", "late"] {
            http:Client failedBodyClient = check new (string `http://localhost:${port}`, httpVersion = httpVersion,
                timeout = 10);
            decimal startTime = time:monotonicNow();
            http:Response|error response = failedBodyClient->get(string `/failedBody/${path}`);
            byte[]|error body = response is error ? response : response.getBinaryPayload();
            decimal elapsed = time:monotonicNow() - startTime;
            string target = string `${httpVersion} /${path}`;
            test:assertTrue(body is error, string `${target}: the failed body was received as complete`);
            test:assertTrue(elapsed < 5d, string `${target}: the failure took ${elapsed}s to reach the client`);
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
