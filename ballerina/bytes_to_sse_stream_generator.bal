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
import ballerina/lang.regexp;
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

# This class incrementally parses an incoming byte stream and detects consecutive
# line feed characters. When two consecutive line feeds ('\n\n' | '\r\r' |
# '\r\n\r\n') are detected, it signifies the end of an SSE (Server-Sent Event)
# message, and a new `SseEvent` record is created to represent this message.
# The stream is buffered while parsing so that fragmented input, including
# one-byte chunks, is handled without requiring one stream read per byte.
class BytesToEventStreamGenerator {
    private final stream<byte[], io:Error?> byteStream;
    private boolean isClosed = false;
    private byte[] lookaheadBuffer = [];
    private byte[] readBuffer = [];
    private int readBufferIndex = 0;

    isolated function init(stream<byte[], io:Error?> byteStream) {
        self.byteStream = byteStream;
    }

    public isolated function next() returns record {|SseEvent value;|}|error? {
        do {
            string? sseEvent = check self.readUntilDoubleLineBreaks();
            if sseEvent is () {
                return;
            }
            return {value: check parseSseEvent(sseEvent)};
        } on fail error e {
            log:printError("failed to construct SseEvent", e);
            return e;
        }
    }

    public isolated function close() returns error? {
        check self.byteStream.close();
        self.isClosed = true;
    }

    private isolated function readUntilDoubleLineBreaks() returns string|error? {
        byte[] buffer = [];
        byte prevByte = 0;
        byte? currentByte = ();
        boolean foundCariageReturnWithNewLine = false;
        while !self.isClosed {
            currentByte = check self.getNextByte();
            if currentByte is () {
                return;
            }
            if foundCariageReturnWithNewLine && currentByte == CARRIAGE_RETURN {
                // Lookahead for newline
                byte? nextByte = check self.getNextByte();
                if nextByte is () {
                    return;
                }
                if nextByte == LINE_FEED {
                    buffer.push(currentByte);
                    buffer.push(nextByte);
                    return string:fromBytes(buffer);
                }
                // Store char in lookahead buffer if not newline
                self.lookaheadBuffer.push(nextByte);
            }
            foundCariageReturnWithNewLine = false;
            if ((currentByte == LINE_FEED || currentByte == CARRIAGE_RETURN) && prevByte == currentByte) {
                buffer.push(currentByte);
                return string:fromBytes(buffer);
            }
            if currentByte == LINE_FEED && prevByte == CARRIAGE_RETURN {
                foundCariageReturnWithNewLine = true;
            }
            buffer.push(currentByte);
            prevByte = currentByte;
        }
        return;
    }

    # Reads next byte from the lookahead buffer or the buffered stream data.
    # + return - A `byte?` on success, `error` on failure
    private isolated function getNextByte() returns byte|error? {
        if self.lookaheadBuffer.length() > 0 {
            return self.lookaheadBuffer.shift();
        }
        while self.readBufferIndex >= self.readBuffer.length() {
            record {byte[] value;}? nextValue = check self.byteStream.next();
            if nextValue is () {
                return;
            }
            self.readBuffer = nextValue.value;
            self.readBufferIndex = 0;
        }
        byte nextByte = self.readBuffer[self.readBufferIndex];
        self.readBufferIndex += 1;
        return nextByte;
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
        regexp:Groups? groups = re `(.*?):(.*)`.findGroups(line);
        string filedName = line;
        string fieldValue = "";
        if groups is regexp:Groups && groups.length() == 3 {
            regexp:Span? filedNameSpan = groups[1];
            regexp:Span? filedValueSpan = groups[2];
            if filedNameSpan is () || filedValueSpan is () {
                continue;
            }
            filedName = filedNameSpan.substring().trim();
            fieldValue = removeLeadingSpace(filedValueSpan.substring());
        }
        if filedName == ID {
            id = fieldValue;
        } else if filedName == COMMENT {
            comment = fieldValue;
        } else if filedName == RETRY {
            int|error retryValue = int:fromString(fieldValue);
            'retry = retryValue is error ? () : retryValue;
        } else if filedName == EVENT {
            eventName = fieldValue;
        } else if filedName == DATA {
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
