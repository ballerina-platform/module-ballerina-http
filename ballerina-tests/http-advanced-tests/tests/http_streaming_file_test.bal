// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/io;
// import ballerina/log;
import ballerina/mime;
import ballerina/test;
import ballerina/file;
import ballerina/http_test_common as common;

final http:Client streamTestClient = check new ("http://localhost:" + streamTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client streamBackendClient = check new ("http://localhost:" + streamTestPort2.toString(), httpVersion = http:HTTP_1_1);

service /'stream on new http:Listener(streamTestPort1, httpVersion = http:HTTP_1_1) {
    resource function get fileupload(http:Caller caller) {
        http:Request request = new;
        request.setFileAsPayload(common:DATA_FILE, contentType = mime:APPLICATION_PDF);
        http:Response|error clientResponse = streamBackendClient->post("/streamBack/receiver", request);

        http:Response res = new;
        if clientResponse is http:Response {
            res = clientResponse;
        } else {
            // log:printError("Error occurred while sending data to the client ", 'error = clientResponse);
            setError(res, clientResponse);
        }
        var result = caller->respond(res);
        if result is error {
            // log:printError("Error while while sending response to the caller", 'error = result);
        }
    }

    resource function get cacheFileupload(http:Caller caller) {
        http:Response res = new;
        res.setFileAsPayload(common:DATA_FILE, contentType = mime:APPLICATION_PDF);
        var result = caller->respond(res);
        if result is error {
            // log:printError("Error while while sending response to the caller", 'error = result);
        }
    }
}

service /streamBack on new http:Listener(streamTestPort2, httpVersion = http:HTTP_1_1) {
    resource function post receiver(http:Caller caller, http:Request request) returns error? {
        http:Response res = new;
        stream<byte[], io:Error?>|error streamer = request.getByteStream();

        if (streamer is stream<byte[], io:Error?>) {
            io:Error? result = io:fileWriteBlocksFromStream(common:RECEIVED_FILE, streamer);

            if result is error {
                // log:printError("error occurred while writing ", 'error = result);
                setError(res, result);
            } else {
                res.setPayload("File Received!");
                _ = check file:remove(common:TEMP_FILES_DIR, file:RECURSIVE); // Removes file.
            }
            var cr = streamer.close();
            if (cr is error) {
                // log:printError("Error occurred while closing the stream: ", 'error = cr);
            }
        } else {
            setError(res, streamer);
        }
        var result = caller->respond(res);
        if result is error {
            // log:printError("Error occurred while sending response", 'error = result);
        }
    }
}

function setError(http:Response res, error err) {
    res.statusCode = 500;
    res.setPayload(err.message());
}

@test:Config {}
function testStreamingLargeFile() returns error? {
    http:Response|error response = streamTestClient->get("/stream/fileupload");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "File Received!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testConsumedStream() returns error? {
    string msg = "Error occurred while retrieving the byte stream from the response";
    string cMsg = "Byte stream is not available but payload can be obtain either as xml, json, string or byte[] type";
    http:Response|error response = streamTestClient->get("/stream/cacheFileupload");
    if response is http:Response {
        byte[]|error bytes = response.getBinaryPayload();
        if bytes is error {
            // log:printError("Error reading payload", 'error = bytes);
        }
        stream<byte[], io:Error?>|error streamer = response.getByteStream();
        if (streamer is stream<byte[], io:Error?>) {
            test:assertFail(msg = "Found unexpected output type");
        } else {
            test:assertEquals(streamer.message(), msg, msg = "Found unexpected output");
            error? cause = streamer.cause();
            if (cause is error) {
                test:assertEquals(cause.message(), cMsg, msg = "Found unexpected output");
            } else {
                test:assertFail(msg = "Found unexpected output type");
            }
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}
