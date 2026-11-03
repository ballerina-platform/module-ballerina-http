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

// Sends three 10 KB blocks, then stalls for longer than the client's timeout before ending the body.
class StallingBody {
    private int count = 0;

    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        self.count += 1;
        if self.count == 4 {
            runtime:sleep(4);
        }
        if self.count > 3 {
            return;
        }
        return {value: "".padEnd(10000, "x").toBytes()};
    }
}

service /stalled on new http:Listener(stalledBodyTestPort) {
    resource function get .() returns http:Response {
        http:Response response = new;
        response.setByteStream(new stream<byte[], io:Error?>(new StallingBody()));
        return response;
    }
}

final http:Client stalledBodyClient = check new (string `http://localhost:${stalledBodyTestPort}`, timeout = 1);

@test:Config {}
function testPayloadGettersFailWhenTheHttp2ResponseBodyIdlesOut() returns error? {
    foreach string getter in ["binary", "text", "json"] {
        decimal startTime = time:monotonicNow();
        http:Response response = check stalledBodyClient->/stalled;
        anydata|error payload = getter == "binary" ? response.getBinaryPayload()
            : getter == "text" ? response.getTextPayload() : response.getJsonPayload();
        decimal elapsed = time:monotonicNow() - startTime;
        test:assertTrue(payload is error, string `the ${getter} payload getter did not fail`);
        test:assertTrue(elapsed < 3.5d, string `the ${getter} payload getter took ${elapsed}s`);
    }
}
