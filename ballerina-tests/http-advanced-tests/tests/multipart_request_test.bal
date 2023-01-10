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

import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

function setErrorResponse(http:Response response, error err) {
    response.statusCode = 500;
    response.setPayload(err.message());
}

listener http:Listener multipartReqEP = new (multipartRequestTestPort, httpVersion = http:HTTP_1_1);
final http:Client multipartReqClient = check new ("http://localhost:" + multipartRequestTestPort.toString(), httpVersion = http:HTTP_1_1);

service /test on multipartReqEP {

    resource function post textbodypart(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            var result = bodyParts[0].getText();
            if (result is string) {
                mime:Entity entity = new;
                entity.setText(result);
                response.setEntity(entity);
            } else {
                setErrorResponse(response, result);
            }
        }

        check caller->respond(response);
    }

    resource function post jsonbodypart(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            var result = bodyParts[0].getJson();
            if (result is json) {
                response.setJsonPayload(result);
            } else {
                setErrorResponse(response, result);
            }
        }
        check caller->respond(response);
    }

    resource function post xmlbodypart(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            var result = bodyParts[0].getXml();
            if (result is xml) {
                response.setXmlPayload(result);
            } else {
                setErrorResponse(response, result);
            }
        }
        check caller->respond(response);
    }

    resource function post binarybodypart(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            var result = bodyParts[0].getByteArray();
            if (result is byte[]) {
                response.setBinaryPayload(result);
            } else {
                setErrorResponse(response, result);
            }
        }
        check caller->respond(response);
    }

    resource function post multipleparts(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            string content = "";
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                content = content + " -- " + handleContent(part);
                i = i + 1;
            }
            response.setTextPayload(content);
        }
        check caller->respond(response);
    }

    resource function post emptyparts(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            response.setPayload("Body parts detected!");
        } else {
            response.setPayload(bodyParts.message());
        }
        check caller->respond(response);
    }

    resource function post nestedparts(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            string payload = "";
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                payload = handleNestedParts(part);
                i = i + 1;
            }
            response.setTextPayload(payload);
        }
        check caller->respond(response);
    }
}

function handleContent(mime:Entity bodyPart) returns string {
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    if (mediaType is mime:MediaType) {
        string baseType = mediaType.getBaseType();
        if (mime:APPLICATION_XML == baseType || mime:TEXT_XML == baseType) {
            var payload = bodyPart.getXml();
            if (payload is xml) {
                return (payload/*).toString();
            } else {
                return "Error in getting xml payload";
            }
        } else if (mime:APPLICATION_JSON == baseType) {
            var payload = bodyPart.getJson();
            if (payload is json) {
                return extractFieldValue(payload.bodyPart);
            } else {
                return "Error in getting json payload";
            }
        } else if (mime:TEXT_PLAIN == baseType) {
            var payload = bodyPart.getText();
            if payload is string {
                return payload;
            } else {
                return "Error in getting string payload";
            }
        } else if (mime:APPLICATION_OCTET_STREAM == baseType) {
            var payload = bodyPart.getByteArray();
            if (payload is byte[]) {
                var stringPayload = strings:fromBytes(payload);
                if (stringPayload is error) {
                    return "Error occurred while byte array to string conversion";
                } else {
                    return stringPayload;
                }
            } else {
                return "Error in getting byte[] payload";
            }
        }
    } else {
        return mediaType.message();
    }
    return "";
}

//Keep this until there's a simpler way to get a string value out of a json
function extractFieldValue(json|error fieldValue) returns string {
    if (fieldValue is string) {
        return fieldValue;
    } else {
        return "error";
    }
}

@test:Config {}
function testMultiplePartsForMixed() {
    mime:Entity textPart1 = new;
    textPart1.setText("Part1");
    textPart1.setHeader("Content-Type", "text/plain; charset=UTF-8");

    mime:Entity textPart2 = new;
    textPart2.setText("Part2");
    textPart2.setHeader("Content-Transfer-Encoding", "binary");

    mime:Entity[] bodyParts = [textPart1, textPart2];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_MIXED);
    http:Response|error response = multipartReqClient->post("/test/multipleparts", request);
    if response is http:Response {
        assertMultipartResponse(response, " -- Part1 -- Part2");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testMultiplePartsForFormData() {
    mime:Entity textPart1 = new;
    textPart1.setText("Part1");
    textPart1.setHeader("Content-Type", "text/plain; charset=UTF-8");
    textPart1.setContentDisposition(getContentDispositionForGivenDisposition("foo", "form-data"));

    mime:Entity textPart2 = new;
    textPart2.setText("Part2");
    textPart2.setHeader("Content-Transfer-Encoding", "binary");
    mime:ContentDisposition contentDisposition = getContentDispositionForGivenDisposition("filepart", "form-data");
    contentDisposition.fileName = "file-01.txt";
    textPart2.setContentDisposition(contentDisposition);

    mime:Entity[] bodyParts = [textPart1, textPart2];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/multipleparts", request);
    if response is http:Response {
        assertMultipartResponse(response, " -- Part1 -- Part2");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testMultiplePartsForNewSubTypes() {
    mime:Entity textPart1 = new;
    textPart1.setText("Part1");
    textPart1.setHeader("Content-Type", "text/plain; charset=UTF-8");
    textPart1.setContentDisposition(getContentDispositionForGivenDisposition("foo", "form-data"));

    mime:Entity textPart2 = new;
    textPart2.setText("Part2");
    textPart2.setHeader("Content-Type", "text/plain");
    textPart2.setHeader("Content-Transfer-Encoding", "binary");
    mime:ContentDisposition contentDisposition = getContentDispositionForGivenDisposition("", "inline");
    textPart2.setContentDisposition(contentDisposition);

    mime:Entity[] bodyParts = [textPart1, textPart2];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = "multipart/new-sub-type");
    http:Response|error response = multipartReqClient->post("/test/multipleparts", request);
    if response is http:Response {
        assertMultipartResponse(response, " -- Part1 -- Part2");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testMultipartsWithEmptyBody() {
    http:Request request = new;
    request.setHeader("contentType", mime:MULTIPART_MIXED);
    http:Response|error response = multipartReqClient->post("/test/emptyparts", request);
    if response is http:Response {
        assertMultipartResponse(response, "Error occurred while retrieving body parts from the request");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testNestedPartsForOneLevel() {
    http:Request request = new;
    request.setBodyParts(createNestedPartRequest(), contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/nestedparts", request);
    if response is http:Response {
        assertMultipartResponse(response, "Child Part 1Child Part 2");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testTextBodyPart() {
    mime:Entity textPart = new;
    textPart.setText("Ballerina text body part", contentType = mime:TEXT_PLAIN);
    http:Request request = new;
    mime:Entity[] bodyParts = [textPart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/textbodypart", request);
    if response is http:Response {
        assertMultipartResponse(response, "Ballerina text body part");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testTextBodyPartAsFileUpload() {
    mime:Entity filePart = new;
    filePart.setFileAsEntityBody(common:TEXT_FILE,
                        contentType = mime:TEXT_PLAIN);
    http:Request request = new;
    mime:Entity[] bodyParts = [filePart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/textbodypart", request);
    if response is http:Response {
        assertMultipartResponse(response, "Ballerina text as a file part");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testJsonBodyPart() {
    mime:Entity jsonPart = new;
    jsonPart.setJson({"bodyPart": "jsonPart"});
    http:Request request = new;
    mime:Entity[] bodyParts = [jsonPart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/jsonbodypart", request);
    if response is http:Response {
        var body = response.getJsonPayload();
        if (body is json) {
            test:assertEquals(body.toJsonString(), "{\"" + "bodyPart" + "\":\"" + "jsonPart" + "\"}",
                    msg = common:errorMessage);
        } else {
            test:assertFail(msg = common:errorMessage + body.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testJsonBodyPartAsFileUpload() {
    mime:Entity jsonFilePart = new;
    jsonFilePart.setFileAsEntityBody(common:JSON_FILE,
                            contentType = mime:APPLICATION_JSON);
    http:Request request = new;
    mime:Entity[] bodyParts = [jsonFilePart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/jsonbodypart", request);
    if response is http:Response {
        var body = response.getJsonPayload();
        if (body is json) {
            test:assertEquals(body.toJsonString(), "{\"" + "name" + "\":\"" + "wso2" + "\"}",
                    msg = common:errorMessage);
        } else {
            test:assertFail(msg = common:errorMessage + body.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testXmlBodyPart() {
    mime:Entity xmlPart = new;
    xmlPart.setXml(xml `<name>Ballerina xml file part</name>`);
    http:Request request = new;
    mime:Entity[] bodyParts = [xmlPart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/xmlbodypart", request);
    if response is http:Response {
        var body = response.getXmlPayload();
        if (body is xml) {
            test:assertEquals(body.toString(), "<name>Ballerina xml file part</name>", msg = common:errorMessage);
        } else {
            test:assertFail(msg = common:errorMessage + body.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testXmlBodyPartAsFileUpload() {
    mime:Entity xmlFilePart = new;
    xmlFilePart.setFileAsEntityBody(common:XML_FILE,
                            contentType = mime:APPLICATION_XML);
    http:Request request = new;
    mime:Entity[] bodyParts = [xmlFilePart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/xmlbodypart", request);
    if response is http:Response {
        var body = response.getXmlPayload();
        if (body is xml) {
            test:assertEquals(body.toString(), "<name>Ballerina xml file part</name>", msg = common:errorMessage);
        } else {
            test:assertFail(msg = common:errorMessage + body.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

// TODO: Enable after the I/O revamp
// @test:Config {}
// function testBinaryBodyPartAsFileUpload() returns  error? {
//     io:ReadableByteChannel byteChannel = check io:openReadableFile
//                                 (common:TMP_FILE);
//     mime:Entity binaryFilePart = new;
//     binaryFilePart.setByteChannel(byteChannel);
//     http:Request request = new;
//     mime:Entity[] bodyParts = [binaryFilePart];
//     request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
//     http:Response|error response = multipartReqClient->post("/test/binarybodypart", request);
//     if response is http:Response {
//         var body = response.getByteChannel();
//         if (body is io:ReadableByteChannel) {
//             io:ReadableCharacterChannel sourceChannel = new (body, "UTF-8");
//             string text = check sourceChannel.read(27);
//             test:assertEquals(text, "Ballerina binary file part", msg = common:errorMessage);
//             close(byteChannel);
//             close(sourceChannel);
//         } else {
//             test:assertFail(msg = common:errorMessage + body.message());
//         }
//     } else {
//         test:assertFail(msg = common:errorMessage + response.message());
//     }
// }

@test:Config {}
function testBinaryBodyPartAsFileUploadUsingStream() returns error? {
    io:ReadableByteChannel byteChannel = check io:openReadableFile
                                (common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    mime:Entity binaryFilePart = new;
    binaryFilePart.setByteStream(blockStream);
    http:Request request = new;
    mime:Entity[] bodyParts = [binaryFilePart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/binarybodypart", request);
    if response is http:Response {
        var str = response.getByteStream();
        if (str is stream<byte[], io:Error?>) {
            record {|byte[] value;|}|io:Error? arr1 = str.next();
            if (arr1 is record {|byte[] value;|}) {
                string name = check strings:fromBytes(arr1.value);
                test:assertEquals(name, "Ballerina binary file part", msg = "Found unexpected output");
                io:Error? arr2 = str.close();
                test:assertTrue(arr2 is (), msg = "Found unexpected output");
            } else {
                test:assertFail(msg = "Found unexpected arr1 output type");
            }
        } else {
            test:assertFail(msg = "Found unexpected str output type" + str.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
    return;
}

// TODO: Enable after the I/O revamp
// @test:Config {}
// function testMultiplePartsWithMultipleBodyTypes() returns  error? {
//     mime:Entity xmlPart = new;
//     xmlPart.setXml(xml `<name>Ballerina xml file part</name>`);

//     mime:Entity jsonPart = new;
//     jsonPart.setJson({"bodyPart":"jsonPart"});

//     mime:Entity textPart = new;
//     textPart.setText("Ballerina text body part", contentType = mime:TEXT_PLAIN);

//     io:ReadableByteChannel readableByteChannel = check io:openReadableFile
//                                 (common:TMP_FILE);
//     mime:Entity binaryFilePart = new;
//     binaryFilePart.setByteChannel(readableByteChannel);

//     mime:Entity[] bodyParts = [xmlPart, jsonPart, textPart, binaryFilePart];
//     http:Request request = new;
//     request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
//     http:Response|error response = multipartReqClient->post("/test/multipleparts", request);

//     if response is http:Response {
//         assertMultipartResponse(response, " -- Ballerina xml file part -- jsonPart -- Ballerina text body part "
//               + "-- Ballerina binary file part");
//         close(readableByteChannel);
//     } else {
//         test:assertFail(msg = common:errorMessage + response.message());
//     }
// }

@test:Config {}
function testMultiplePartsWithMultipleBodyTypesIncludingStreams() returns error? {
    mime:Entity xmlPart = new;
    xmlPart.setXml(xml `<name>Ballerina xml file part</name>`);

    mime:Entity jsonPart = new;
    jsonPart.setJson({"bodyPart": "jsonPart"});

    mime:Entity textPart = new;
    textPart.setText("Ballerina text body part", contentType = mime:TEXT_PLAIN);

    io:ReadableByteChannel byteChannel = check io:openReadableFile
                                (common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    mime:Entity binaryFilePart = new;
    binaryFilePart.setByteStream(blockStream);

    mime:Entity[] bodyParts = [xmlPart, jsonPart, textPart, binaryFilePart];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/multipleparts", request);

    if response is http:Response {
        assertMultipartResponse(response, " -- Ballerina xml file part -- jsonPart -- Ballerina text body part "
            + "-- Ballerina binary file part");
        check close(byteChannel);
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
    return;
}

@test:Config {}
function testTextBodyPartWith7BitEncoding() {
    mime:Entity textPart = new;
    textPart.setText("èiiii");
    textPart.setHeader("Content-Transfer-Encoding", "7bit");
    http:Request request = new;
    mime:Entity[] bodyParts = [textPart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/textbodypart", request);
    if response is http:Response {
        assertMultipartResponse(response, "èiiii");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testTextBodyPartWith8BitEncoding() {
    mime:Entity textPart = new;
    textPart.setText("èlllll");
    textPart.setHeader("Content-Transfer-Encoding", "8bit");
    http:Request request = new;
    mime:Entity[] bodyParts = [textPart];
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartReqClient->post("/test/textbodypart", request);
    if response is http:Response {
        assertMultipartResponse(response, "èlllll");
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

function getContentDispositionForGivenDisposition(string partName, string disposition) returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    if (partName != "") {
        contentDisposition.name = partName;
    }
    contentDisposition.disposition = disposition;
    return contentDisposition;
}

function close(io:ReadableByteChannel|io:ReadableCharacterChannel ch) returns error? {
    object {
        public function close() returns error?;
    } channelResult = ch;
    return channelResult.close();
}
