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

import ballerina/io;
import ballerina/log;

const byte LINE_FEED = 10;
const byte CARRIAGE_RETURN = 13;

enum SseFieldName {
    COMMENT = "",
    ID = "id",
    RETRY = "retry",
    EVENT = "event",
    DATA = "data"
};

# Turns a byte stream of server-sent events into `SseEvent` records.
#
# Each read returns the bytes received so far, in chunks of any size, down to one byte at a time. The chunks are
# scanned for the end of an event, two consecutive line breaks ('\n\n' | '\r\r' | '\r\n\r\n'), and the bytes
# of an unfinished event are carried over to the next chunk. An event is decoded only once it is complete, so a
# multi-byte character split across chunks stays intact.
class BytesToEventStreamGenerator {
    private final stream<byte[], io:Error?> byteStream;
    private boolean isClosed = false;
    private byte[] pending = [];
    // Start of the first event in `pending` not yet returned.
    private int eventStart = 0;
    // Where to resume looking for the end of that event, so each byte is scanned once.
    private int scanFrom = 0;

    isolated function init(stream<byte[], io:Error?> byteStream) {
        self.byteStream = byteStream;
    }

    public isolated function next() returns record {|SseEvent value;|}|error? {
        do {
            byte[]? sseEvent = check self.readUntilDoubleLineBreaks();
            if sseEvent is () {
                return;
            }
            return {value: check parseSseEvent(check string:fromBytes(sseEvent))};
        } on fail error e {
            log:printError("failed to construct SseEvent", e);
            return e;
        }
    }

    public isolated function close() returns error? {
        check self.byteStream.close();
        self.isClosed = true;
    }

    private isolated function readUntilDoubleLineBreaks() returns byte[]|error? {
        while !self.isClosed {
            int? eventEnd = self.findEventEnd();
            if eventEnd is int {
                byte[] sseEvent = self.pending.slice(self.eventStart, eventEnd);
                self.eventStart = eventEnd;
                return sseEvent;
            }
            record {byte[] value;}? chunk = check self.byteStream.next();
            if chunk is () {
                return;
            }
            if self.eventStart > 0 {
                self.pending = self.pending.slice(self.eventStart);
                self.scanFrom -= self.eventStart;
                self.eventStart = 0;
            }
            self.pending.push(...chunk.value);
        }
        return;
    }

    # Finds the end of the event starting at `eventStart`, looking only at the bytes not scanned before.
    # + return - The index just past the event's terminating line breaks, or `()` if they have not arrived yet
    private isolated function findEventEnd() returns int? {
        byte[] bytes = self.pending;
        int eventStart = self.eventStart;
        int length = bytes.length();
        int i = int:max(self.scanFrom, eventStart);
        while i < length {
            byte current = bytes[i];
            if i > eventStart && (current == LINE_FEED || current == CARRIAGE_RETURN) {
                byte previous = bytes[i - 1];
                if previous == current {
                    self.scanFrom = i + 1;
                    return i + 1;
                }
                if current == LINE_FEED && previous == CARRIAGE_RETURN && i - 3 >= eventStart
                        && bytes[i - 2] == LINE_FEED && bytes[i - 3] == CARRIAGE_RETURN {
                    self.scanFrom = i + 1;
                    return i + 1;
                }
            }
            i += 1;
        }
        self.scanFrom = length;
        return;
    }
}

isolated function parseSseEvent(string event) returns SseEvent|error {
    string[] lines = re `\r\n|\n|\r`.split(event);
    string? id = ();
    string? comment = ();
    string? data = ();
    int? 'retry = ();
    string? eventName = ();

    foreach string line in lines {
        if line == "" {
            continue;
        }
        string fieldName = line;
        string fieldValue = "";
        int? colonIndex = line.indexOf(":");
        if colonIndex is int {
            fieldName = line.substring(0, colonIndex).trim();
            fieldValue = removeLeadingSpace(line.substring(colonIndex + 1));
        }
        if fieldName == ID {
            id = fieldValue;
        } else if fieldName == COMMENT {
            comment = fieldValue;
        } else if fieldName == RETRY {
            int|error retryValue = int:fromString(fieldValue);
            'retry = retryValue is error ? () : retryValue;
        } else if fieldName == EVENT {
            eventName = fieldValue;
        } else if fieldName == DATA {
            if data is () {
                data = fieldValue;
            } else {
                data += fieldValue;
            }
        }
    }
    return {data, id, comment, 'retry, event: eventName};
}

isolated function removeLeadingSpace(string line) returns string {
    return line.startsWith(" ") ? line.substring(1) : line;
}
