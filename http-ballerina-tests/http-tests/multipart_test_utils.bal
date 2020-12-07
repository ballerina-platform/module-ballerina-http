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

import ballerina/http;
import ballerina/mime;
import ballerina/test;

const string errorMessage = "Found an unexpected output:";

public function assertMultipartResponse(http:Response response, string expected) {
    var body = response.getTextPayload();
    if (body is string) {
        test:assertEquals(body, expected, msg = errorMessage);
    } else {
        test:assertFail(msg = errorMessage + body.message());
    }
}

function createNestedPartRequest() returns mime:Entity[] {
    mime:Entity parentPart1 = new;
    parentPart1.setText("Parent Part");
    parentPart1.setHeader("Content-Type", "text/plain; charset=UTF-8");
    parentPart1.setContentDisposition(getContentDispositionForGivenDisposition("parent1", "form-data"));

    mime:Entity childPart1 = new;
    childPart1.setText("Child Part 1");
    childPart1.setHeader("Content-Type", "text/plain");
    childPart1.setHeader("Content-Transfer-Encoding", "binary");
    mime:ContentDisposition childPart1ContentDisposition = getContentDispositionForGivenDisposition("", "attachment");
    childPart1ContentDisposition.fileName = "file-02.txt";
    childPart1.setContentDisposition(childPart1ContentDisposition);

    mime:Entity childPart2 = new;
    childPart2.setText("Child Part 2");
    childPart2.setHeader("Content-Type", "text/plain");
    childPart2.setHeader("Content-Transfer-Encoding", "binary");
    mime:ContentDisposition childPart2contentDisposition = getContentDispositionForGivenDisposition("", "attachment");
    childPart2contentDisposition.fileName = "file-02.txt";
    childPart2.setContentDisposition(childPart2contentDisposition);

    mime:Entity[] childParts = [childPart1, childPart2];
    parentPart1.setBody(childParts);

    mime:Entity[] bodyParts = [parentPart1];
    return bodyParts;
}

function handleNestedParts(mime:Entity parentPart) returns @tainted string {
    string content = "";
    string contentTypeOfParent = parentPart.getContentType();
    if (contentTypeOfParent.startsWith("multipart/")) {
        var childParts = parentPart.getBodyParts();
        if (childParts is mime:Entity[]) {
            int i = 0;
            while (i < childParts.length()) {
                mime:Entity childPart = childParts[i];
                content = content + handleContent(childPart);
                i = i + 1;
            }
        } else {
            return "Error decoding nested parts";
        }
    }
    return content;
}
