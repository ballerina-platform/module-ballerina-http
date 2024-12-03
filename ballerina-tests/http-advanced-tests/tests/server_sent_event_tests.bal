// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

listener http:Listener http1SseListener = new http:Listener(http1SsePort, httpVersion = http:HTTP_1_1);
listener http:Listener http2SseListener = new http:Listener(http2SsePort);
final http:Client http1SseClient = check new (string `http://localhost:${http1SsePort}`, httpVersion = http:HTTP_1_1);
final http:Client http2SseClient = check new (string `http://localhost:${http2SsePort}`, timeout = 120);

class SseEventGenerator {
    private final int eventCount;
    private boolean completeWithError;
    private int currentEventCount = 0;

    function init(int eventCount = 10, boolean completeWithError = false) {
        self.eventCount = eventCount;
        self.completeWithError = completeWithError;
    }

    public isolated function next() returns record {|http:SseEvent value;|}|error? {
        runtime:sleep(0.1);
        http:SseEvent sseEvent = {data: string `count: ${self.currentEventCount}`, id: self.currentEventCount.toString()};
        if self.currentEventCount == 0 {
            sseEvent.event = "start";
        } else if self.currentEventCount == self.eventCount {
            sseEvent.event = "end";
        } else {
            sseEvent.event = "continue";
            sseEvent.'retry = 10;
        }
        if self.currentEventCount > self.eventCount {
            return self.completeWithError ? error("ending with error") : ();
        }
        self.currentEventCount += 1;
        return {value: sseEvent};
    }
}

class SseEventGenerator2 {
    private final int eventCount;
    private int currentEventCount = 0;

    public isolated function next() returns record {|http:SseEvent value;|}|error {
        http:SseEvent sseEvent = {data: string `count: ${self.currentEventCount}`, id: self.currentEventCount.toString()};
        if self.currentEventCount == 0 {
            sseEvent.event = "start";
        } else {
            sseEvent.event = "continue";
            sseEvent.'retry = 10;
        }
        if self.currentEventCount > 3 {
            return error("ending with error");
        }
        self.currentEventCount += 1;
        return {value: sseEvent};
    }
}

service /sse on http1SseListener {
    resource function 'default [string... paths](http:Request req) returns stream<http:SseEvent, error?> {
        return new (new SseEventGenerator());
    }
}

service /sse on http2SseListener {
    resource function post .(http:Request req) returns http:Response {
        http:Response response = new;
        stream<http:SseEvent, error?> sseEventStream = new (new SseEventGenerator());
        response.setSseEventStream(sseEventStream);
        return response;
    }

    resource function get completeWithError() returns stream<http:SseEvent, error?> {
        return new (new SseEventGenerator(3, true));
    }

    resource function get completeWithError2() returns stream<http:SseEvent, error> {
        return new (new SseEventGenerator2());
    }
}

@test:Config {}
function testHttp1ResponseHeadersForSseEventStream() returns error? {
    http:Response response = check http1SseClient->/sse;
    test:assertEquals(response.getHeader("Connection"), "keep-alive");
    test:assertEquals(response.getHeader("Content-Type"), "text/event-stream");
    test:assertEquals(response.getHeader("Transfer-Encoding"), "chunked");
    test:assertTrue((check response.getHeader("Cache-Control")).startsWith("no-cache"));
    stream<http:SseEvent, error?> actualSseEvents = check response.getSseEventStream();
    stream<http:SseEvent, error?> expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);
}

@test:Config {}
function testHttp2ResponseHeadersForSseEventStream() returns error? {
    http:Response response = check http2SseClient->/sse.post({});
    test:assertTrue(response.getHeader("Connection") is http:HeaderNotFoundError);
    test:assertEquals(response.getHeader("Content-Type"), "text/event-stream");
    test:assertTrue((check response.getHeader("Cache-Control")).startsWith("no-cache"));
    stream<http:SseEvent, error?> actualSseEvents = check response.getSseEventStream();
    stream<http:SseEvent, error?> expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);
}

@test:Config {}
function testClientDataBindingForSseEventStream() returns error? {
    stream<http:SseEvent, error?> actualSseEvents = check http1SseClient->/sse;
    stream<http:SseEvent, error?> expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);
}

@test:Config {}
function testClientDataBindingFailure() returns error? {
    stream<http:SseEvent, error?>|json|error actualSseEvents = http1SseClient->/sse;
    if actualSseEvents is error {
        test:assertEquals(actualSseEvents.message(), "payload binding failed: " +
                "Target return type must not be a union of stream<http:SseEvent, error?> and anydata");
    } else {
        test:assertFail("An error expected");
    }
}

@test:Config {}
function testClientRequestMethodsWithStreamType() returns error? {
    stream<http:SseEvent, error?> actualSseEvents = check http1SseClient->/sse;
    stream<http:SseEvent, error?> expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http1SseClient->/sse.delete();
    expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http1SseClient->/sse.options();
    expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http1SseClient->/sse.post({});
    expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http1SseClient->/sse.put({});
    expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http1SseClient->/sse.patch({});
    expectedSseEvents = new (new SseEventGenerator());
    check assertEventStream(actualSseEvents, expectedSseEvents);
}

@test:Config {}
function testServiceCompletesStreamWithErrorEvent() returns error? {
    stream<http:SseEvent, error?> actualSseEvents = check http2SseClient->/sse/completeWithError;
    stream<http:SseEvent, error?> expectedSseEvents = new (new SseEventGenerator(3, true));
    check assertEventStream(actualSseEvents, expectedSseEvents);

    actualSseEvents = check http2SseClient->/sse/completeWithError2;
    expectedSseEvents = new (new SseEventGenerator2());
    check assertEventStream(actualSseEvents, expectedSseEvents);
}

isolated function assertEventStream(stream<http:SseEvent, error?> actualSseEvents, stream<http:SseEvent, error?> expectedSseEvents) returns error? {
    error? err = from http:SseEvent expectedEvent in expectedSseEvents
        do {
            record {|http:SseEvent value;|}? valueRecord = check actualSseEvents.next();
            test:assertEquals(valueRecord?.value, expectedEvent);
        };
    if err is error {
        http:SseEvent expectedEvent = {event: "error", data: err.message()};
        record {|http:SseEvent value;|}? valueRecord = check actualSseEvents.next();
        test:assertEquals(valueRecord?.value, expectedEvent);
    }
}
