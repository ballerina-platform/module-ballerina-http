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
import ballerina/lang.runtime;
import ballerina/test;

listener http:Listener concurrentRedirectListener = new (concurrentRedirectTestPort, httpVersion = http:HTTP_1_1);

service /chain on concurrentRedirectListener {
    resource function get hop/[int n]() returns http:TemporaryRedirect|string {
        if n == 0 {
            return "done";
        }
        // Keeps the redirect chains of concurrent requests overlapping.
        runtime:sleep(0.05);
        return {headers: {"Location": string `/chain/hop/${n - 1}`}};
    }
}

final http:Client concurrentRedirectClient = check new (string `http://localhost:${concurrentRedirectTestPort}`,
    httpVersion = http:HTTP_1_1, followRedirects = {enabled: true, maxCount: 3});

isolated function followChain(int hops) returns http:Response|error {
    return concurrentRedirectClient->get(string `/chain/hop/${hops}`);
}

@test:Config {}
function testConcurrentRedirectsCountedPerRequest() returns error? {
    future<http:Response|error>[] withinLimit = [];
    future<http:Response|error>[] overLimit = [];
    foreach int i in 0 ..< 10 {
        future<http:Response|error> shortChain = start followChain(2);
        withinLimit.push(shortChain);
        future<http:Response|error> longChain = start followChain(5);
        overLimit.push(longChain);
    }
    foreach future<http:Response|error> f in withinLimit {
        http:Response response = check wait f;
        test:assertEquals(response.statusCode, 200, "A request needing 2 of the 3 allowed redirects was cut short");
        test:assertEquals(check response.getTextPayload(), "done");
    }
    foreach future<http:Response|error> f in overLimit {
        http:Response response = check wait f;
        test:assertEquals(response.statusCode, 307, "A request needing 5 redirects followed more than the 3 allowed");
        test:assertEquals(response.resolvedRequestedURI,
            string `http://localhost:${concurrentRedirectTestPort}/chain/hop/2`);
    }
}
